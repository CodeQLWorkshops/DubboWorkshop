import java

from MethodAccess ma
where
  ma.getMethod().getName().regexpMatch("deserialize|realize") and
  ma.getMethod().getDeclaringType().getName().regexpMatch("PojoUtils|JavaBeanSerializeUtil") and
  not ma.getEnclosingCallable().getDeclaringType().getName().regexpMatch("PojoUtils|JavaBeanSerializeUtil") and
  not ma.getLocation().getFile().getAbsolutePath().matches("%/src/test/%")
select ma, ma.getEnclosingCallable().getDeclaringType()