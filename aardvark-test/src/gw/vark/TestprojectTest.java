/*
 * Copyright (c) 2010 Guidewire Software, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package gw.vark;

import gw.lang.reflect.IType;
import gw.lang.reflect.TypeSystem;
import gw.lang.reflect.gs.IGosuClass;
import gw.lang.reflect.gs.IGosuProgram;
import gw.lang.shell.Gosu;
import gw.vark.testapi.AardvarkTest;
import gw.vark.testapi.InMemoryLogger;
import gw.vark.testapi.StringMatchAssertion;
import gw.vark.testapi.TestUtil;
import junit.framework.Assert;
import org.apache.tools.ant.Project;
import org.junit.BeforeClass;
import org.junit.Test;

import java.io.File;

/**
 * A test class for running targets with a one-time Gosu initialization.
 *
 * Take note that this won't play nice if run in the same session as other
 * test classes, since it taints the environment by initializing Gosu.
 */
public class TestprojectTest extends AardvarkTest {

  private static File _varkFile;
  private static IGosuProgram _gosuProgram;

  @BeforeClass
  public static void initGosu() throws Exception {
    Aardvark.setProject(new Project()); // this allows Gosu initialization to have a Project to log to
    File home = TestUtil.getHome(TestprojectTest.class);
    _varkFile = new File(home, "testproject/build.vark");
    Gosu.init(_varkFile, Aardvark.getSystemClasspath());
    _gosuProgram = Aardvark.parseAardvarkProgram(_varkFile).getGosuProgram();
  }

  @Test
  public void echoHello() {
    InMemoryLogger logger = vark("echo-hello");
    assertThat(logger).matches(
            StringMatchAssertion.exact(""),
            StringMatchAssertion.exact("echo-hello:"),
            StringMatchAssertion.exact("     [echo] Hello World"),
            StringMatchAssertion.exact(""),
            StringMatchAssertion.exact("BUILD SUCCESSFUL"),
            StringMatchAssertion.regex("Total time: \\d+ seconds?"));
  }

  @Test
  public void enhancementContributedTargetIsPresent() {
    IType type = TypeSystem.getByFullNameIfValid("vark.SampleVarkFileEnhancement");
    if (!type.isValid()) {
      Assert.fail("Enhancement should be valid: " + ((IGosuClass) type).getParseResultsException().getFeedback());
    }
    InMemoryLogger logger = vark("-p");
    assertThat(logger).containsLinesThatContain("target-from-enhancement");
    assertThat(logger).excludesLinesThatContain("not-a-target-from-enhancement");
  }

  @Test
  public void targetWithArg() {
    InMemoryLogger results = vark("target-with-arg", "-foo", "echo-hello");
    assertThat(results).matches(
            StringMatchAssertion.exact(""),
            StringMatchAssertion.exact("target-with-arg:"),
            StringMatchAssertion.exact("     [echo] foo: echo-hello"),
            StringMatchAssertion.exact(""),
            StringMatchAssertion.exact("BUILD SUCCESSFUL"),
            StringMatchAssertion.regex("Total time: \\d+ seconds?"));
  }

  @Test
  public void targetWithArgButNoValue() {
    try {
      vark("target-with-arg", "-foo");
      Assert.fail("expected " + IllegalArgumentException.class.getSimpleName());
    }
    catch (IllegalArgumentException e) {
      assertThat(e).hasMessage("\"foo\" is expected to be followed by a value");
    }
  }

  @Test
  public void targetWithArgButNoArg() {
    try {
      vark("target-with-arg");
      Assert.fail("expected " + IllegalArgumentException.class.getSimpleName());
    }
    catch (IllegalArgumentException e) {
      assertThat(e).hasMessage("requires parameter \"foo\"");
    }
  }

  @Test
  public void targetWithArgWithNonexistentArg() {
    try {
      vark("target-with-arg", "-foo", "somestring", "-bar", "somestring");
      Assert.fail("expected " + IllegalArgumentException.class.getSimpleName());
    }
    catch (IllegalArgumentException e) {
      assertThat(e).hasMessage("no parameter named \"bar\"");
    }
  }

  // this is a known break, as default values aren't officially supported
  //@Test
  public void targetWithDefaultValueArg() {
    InMemoryLogger results = vark("target-with-default-value-arg");
    assertThat(results).matches(
            StringMatchAssertion.exact(""),
            StringMatchAssertion.exact("target-with-default-value-arg:"),
            StringMatchAssertion.exact("     [echo] foo: baz"),
            StringMatchAssertion.exact(""),
            StringMatchAssertion.exact("BUILD SUCCESSFUL"),
            StringMatchAssertion.regex("Total time: \\d+ seconds?"));
  }

  @Test
  public void targetWithDefaultValueArgWithUserValue() {
    InMemoryLogger results = vark("target-with-default-value-arg", "-foo", "somestring");
    assertThat(results).matches(
            StringMatchAssertion.exact(""),
            StringMatchAssertion.exact("target-with-default-value-arg:"),
            StringMatchAssertion.exact("     [echo] foo: somestring"),
            StringMatchAssertion.exact(""),
            StringMatchAssertion.exact("BUILD SUCCESSFUL"),
            StringMatchAssertion.regex("Total time: \\d+ seconds?"));
  }

  private InMemoryLogger vark(String... args) {
    InMemoryLogger logger = new InMemoryLogger();
    Aardvark aardvark = new Aardvark(logger);
    aardvark.runBuild(_varkFile, _gosuProgram, new AardvarkOptions(args));
    return logger;
  }
}