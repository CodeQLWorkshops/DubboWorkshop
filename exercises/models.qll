import java
import semmle.code.java.dataflow.FlowSources

/** source from exercise 7 */
class NotifyListener extends RefType {
    NotifyListener() {
    this.hasQualifiedName("org.apache.dubbo.registry", "NotifyListener")
    }
}

class ConfigurationListener extends RefType {
    ConfigurationListener() {
    this.hasQualifiedName("org.apache.dubbo.common.config.configcenter", "ConfigurationListener")
    }
}

class ConfigurationListenerProcessMethod extends Method {
    ConfigurationListenerProcessMethod() {
    this.getName() = "process" and
    this.getDeclaringType().getASupertype*() instanceof ConfigurationListener
    }
}

class NotifyListenerNotifyMethod extends Method {
    NotifyListenerNotifyMethod() {
    this.getName() = "notify" and
    this.getDeclaringType().getASupertype*() instanceof NotifyListener 
    }
}

class ConfigListener extends RemoteFlowSource {
    ConfigListener() {
    (exists(NotifyListenerNotifyMethod m |
        this.asParameter() = m.getAParameter()
        ) or
        exists(ConfigurationListenerProcessMethod m |
        this.asParameter() = m.getAParameter() 
        )) and
        not this.getLocation().getFile().getAbsolutePath().matches("%/src/test/%")
    }
    override string getSourceType() { result = "Config Listener Source" }
}

/** A call to the method `stream` declared in a collection type. */
class CollectionStreamCall extends MethodAccess {
    CollectionStreamCall() { this.getMethod().(CollectionMethod).getName() = "stream" }
}

/** Track taint from `x` to `x.stream()` where `x` is a collection. */
class CollectionStreamTaintStep extends TaintTracking::AdditionalTaintStep {
    override predicate step(DataFlow::Node n1, DataFlow::Node n2) {
    exists(CollectionStreamCall call |
        n1.asExpr() = call.getQualifier() and
        n2.asExpr() = call
    )
    }
}

/** The interface `java.util.stream.Stream`. */
class TypeStream extends Interface {
    TypeStream() { this.hasQualifiedName("java.util.stream", "Stream") }
}

/** A method declared in a stream type, that is, a subtype of `java.util.stream.Stream`. */
class StreamMethod extends Method {
    StreamMethod() { this.getDeclaringType().getASourceSupertype+() instanceof TypeStream }
}

/** A call to the method `collect` declared in a stream type. */
class StreamCollectCall extends MethodAccess {
    StreamCollectCall() { this.getMethod().(StreamMethod).getName() = "collect" }
}

/** Track taint from `stream` to `stream.collect(lambda)`. */
class StreamCollectTaintStep extends TaintTracking::AdditionalTaintStep {
    override predicate step(DataFlow::Node n1, DataFlow::Node n2) {
    exists(StreamCollectCall call |
        n1.asExpr() = call.getQualifier() and
        n2.asExpr() = call
    )
    }
}

/** A call to the method `filter` declared in a stream type. */
class StreamFilterCall extends MethodAccess {
StreamFilterCall() { this.getMethod().(StreamMethod).getName() = "filter" }
}

/** Track taint from `stream` to `stream.filter(lambda)`. */
class StreamFilterTaintStep extends TaintTracking::AdditionalTaintStep {
override predicate step(DataFlow::Node n1, DataFlow::Node n2) {
    exists(MethodAccess ma |
    ma instanceof StreamFilterCall and
    n1.asExpr() = ma.getQualifier() and
    n2.asExpr() = ma
    )
}
}

class URLTaintStep extends TaintTracking::AdditionalTaintStep {
override predicate step(DataFlow::Node n1, DataFlow::Node n2) {
    exists(MethodAccess ma |
    ma.getMethod().getName() = "getParameterAndDecoded" and
    n1.asExpr() = ma.getQualifier() and
    n2.asExpr() = ma
    )
}
}