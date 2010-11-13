package buildr.ajc;

import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.annotation.Before;
import org.aspectj.lang.annotation.Pointcut;

/**
 * @author nico.mainka
 *
 */
@Aspect
public class FooAspect {

	private static boolean worksFine;
	
	@Pointcut("execution(* foo(..))")
	public void fooPointcut() {}
	
	@Before("fooPointcut()")
	public void beforeFoo() {
		worksFine = true;
	}
	
	public static boolean isWorksFine() {
		return worksFine;
	}
	
	public static void init() {
		worksFine = false;
	}
}
