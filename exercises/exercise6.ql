import java
import semmle.code.java.security.UnsafeDeserializationQuery

from UnsafeDeserializationSink node
where
  not node.getLocation().getFile().getAbsolutePath().matches("%/src/test/%")
select node.asExpr().getParent(), node.asExpr().getParent().(Call).getEnclosingCallable().getDeclaringType()
