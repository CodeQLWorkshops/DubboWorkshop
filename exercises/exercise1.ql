import java
import semmle.code.java.dataflow.FlowSources

from RemoteFlowSource source
where
  not source.getLocation().getFile().getAbsolutePath().matches("%/src/test/%")
select source.getEnclosingCallable().getDeclaringType(), source.getSourceType()

