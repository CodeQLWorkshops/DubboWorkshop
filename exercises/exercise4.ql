import java

class ObjectInputClass extends RefType {
  ObjectInputClass() {
    this.getASourceSupertype*().hasQualifiedName("org.apache.dubbo.common.serialize", "ObjectInput")
  }
}

class ReadObjectCall extends MethodAccess {
    ReadObjectCall() {
        exists(Method m |
            this.getMethod() = m and
            m.getName().matches("readObject") and
            m.getDeclaringType() instanceof ObjectInputClass
        )
    }
}

from ReadObjectCall call
where
    not call.getEnclosingCallable().getDeclaringType() instanceof ObjectInputClass and
    not call.getLocation().getFile().getAbsolutePath().matches("%/src/test/%")
select call, call.getEnclosingCallable(), call.getEnclosingCallable().getDeclaringType()
