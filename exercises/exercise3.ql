/**
 * @kind path-problem
 */
import java
import semmle.code.java.dataflow.TaintTracking
import DataFlow::PathGraph

class InsecureConfig extends TaintTracking::Configuration {
  InsecureConfig() { this = "InsecureConfig" }

  override predicate isSource(DataFlow::Node source) {
    exists(Method m |
      m.getName() = "decodeBody" and
      m.getDeclaringType().hasQualifiedName("org.apache.dubbo.rpc.protocol.dubbo", "DubboCodec") and
      m.getParameter(1) = source.asParameter()
     )
  }
/*
  override predicate isAdditionalTaintStep(DataFlow::Node n1, DataFlow::Node n2) {
    exists(MethodAccess ma |
      ma.getMethod().getName() = "deserialize" and
      ma.getMethod().getDeclaringType().hasQualifiedName("org.apache.dubbo.common.serialize", "Serialization") and
      ma.getArgument(1) = n1.asExpr() and
      ma = n2.asExpr()
    )
  }
  */

  override predicate isSink(DataFlow::Node sink) {
    exists(MethodAccess ma |
      ma.getMethod().getName().matches("read%") and
      ma.getMethod()
          .getDeclaringType()
          .getASourceSupertype*()
          .hasQualifiedName("org.apache.dubbo.common.serialize", "ObjectInput") and
      ma.getQualifier() = sink.asExpr()
    )
  }
}

from InsecureConfig conf, DataFlow::PathNode source, DataFlow::PathNode sink
where conf.hasFlowPath(source, sink)
select sink, source, sink, "unsafe deserialization"
