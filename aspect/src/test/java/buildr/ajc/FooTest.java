/**
 * 
 */
package buildr.ajc;

import org.hamcrest.core.Is;
import org.junit.Assert;
import org.junit.Before;
import org.junit.Test;


/**
 * @author nico.mainka
 */
public class FooTest {

	@Before
	public void setup() {
		FooAspect.init();
		Assert.assertThat(FooAspect.isWorksFine(), Is.is(false));
	}

	@Test
	public void foo_called_aspectWorksFine() throws Exception {
		new Foo().foo();
		Assert.assertThat("aspect should be work with project classes",FooAspect.isWorksFine(), Is.is(true));
	}
	
	@Test
	public void test_foo_called_aspectWorksFine() throws Exception {
		foo();
		Assert.assertThat("aspect should be work with test classes",FooAspect.isWorksFine(), Is.is(true));
	}
	private void foo() {	}
}
