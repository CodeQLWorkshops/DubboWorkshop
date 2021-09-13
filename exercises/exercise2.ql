import java
import semmle.code.java.dataflow.FlowSources

class ByteToMessageDecoder extends Class {
    ByteToMessageDecoder() {
      this.getASourceSupertype*().hasQualifiedName("io.netty.handler.codec", "ByteToMessageDecoder")
    }
}

class DecodeMethod extends Method {
  DecodeMethod() {
      this.getName().matches("decode%") and
      this.getDeclaringType() instanceof ByteToMessageDecoder
  }
}

class DecodeSource extends RemoteFlowSource {
  DecodeSource() {
    exists(DecodeMethod m |
      this.asParameter() = m.getParameter(1)
    )
  }
  override string getSourceType() { result = "Netty Channel Source" }
}

class ChannelInboundHandler extends Class {
  ChannelInboundHandler() {
    this.getASourceSupertype*().hasQualifiedName("io.netty.channel", "ChannelInboundHandler")
  }
}

class ChannelReadMethod extends Method {
  ChannelReadMethod() {
      this.getName().matches("channelRead%") and
      this.getDeclaringType() instanceof ChannelInboundHandler
  }
}

class ChannelReadSource extends RemoteFlowSource {
    ChannelReadSource() {
      exists(ChannelReadMethod m |
        this.asParameter() = m.getParameter(1)
      )
    }
    override string getSourceType() { result = "Netty Channel Source" }
}

from RemoteFlowSource source, Class c
where
  (source instanceof ChannelReadSource or
  source instanceof DecodeSource) and
  c = source.getEnclosingCallable().getDeclaringType() and
  not source.getLocation().getFile().getAbsolutePath().matches("%/src/test/%")
select c, source.getSourceType()

  