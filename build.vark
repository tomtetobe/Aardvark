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

uses gw.util.Shell
uses java.io.File
uses java.lang.System
uses java.util.HashMap
uses org.apache.tools.ant.BuildException

var rootDir = file( "" )
var buildDir = file( "build" )
var distDir = buildDir.file("aardvark")
var launcherModule = file( "launcher" )
var aardvarkModule = file( "aardvark" )
var aardvarkTestModule = file( "aardvark-test" )
var releasesDepotPath = "//depot/aardvark/..."

function compileLauncher() {
  var classesDir = launcherModule.file( "classes" )
  Ant.mkdir(:dir = classesDir)
  Ant.copy(
          :filesetList = { launcherModule.file("src").fileset(null, "**/*.java") },
          :todir = classesDir,
          :includeemptydirs = false)
  Ant.javac(
          :srcdir = path(launcherModule.file("src")),
          :destdir = classesDir,
          :classpath = classpath(file("lib/ant/ant-launcher.jar")),
          :debug = true,
          :includeantruntime = false)
}

@Depends("compileLauncher")
function jarLauncher() {
  var destDir = launcherModule.file("dist")
  var classesDir = launcherModule.file("classes")
  Ant.mkdir(:dir = destDir)
  Ant.jar(
          :destfile = destDir.file("aardvark-launcher.jar"),
          :basedir = classesDir,
          :zipfilesetList = { rootDir.zipfileset(:includes = "LICENSE", :prefix = "META-INF") })
}

@Depends("compileLauncher")
function compileAardvark() {
  var classesDir = aardvarkModule.file( "classes" )
  Ant.mkdir(:dir = classesDir)
  Ant.copy(
          :filesetList = { aardvarkModule.file("src").fileset(null, "**/*.java") },
          :todir = classesDir,
          :includeemptydirs = false)
  Ant.javac(
          :srcdir = path(aardvarkModule.file("src")),
          :destdir = classesDir,
          :classpath = classpath( rootDir.fileset( "lib/ant/*.jar,lib/gosu/gw-gosu-core-api.jar,lib/gosu/gw-gosu-core.jar", null ) )
              .withFile( launcherModule.file("classes" ) ),
          :debug = true,
          :includeantruntime = false)
}

@Depends("compileAardvark")
function jarAardvark() {
  var destDir = aardvarkModule.file("dist")
  var classesDir = aardvarkModule.file("classes")
  Ant.mkdir(:dir = destDir)
  Ant.jar(
          :destfile = destDir.file("aardvark.jar"),
          :basedir = classesDir,
          :zipfilesetList = { rootDir.zipfileset(:includes = "LICENSE", :prefix = "META-INF") })
}

@Depends("compileAardvark")
function compileAardvarkTest() {
  var classesDir = aardvarkTestModule.file( "classes" )
  Ant.mkdir(:dir = classesDir)
  Ant.javac(
          :srcdir = path(aardvarkTestModule.file("src")),
          :destdir = classesDir,
          :classpath = classpath( rootDir.fileset( "lib/ant/*.jar,lib/gosu/gw-gosu-core-api.jar,lib/test/*.jar", null ) )
              .withFile( launcherModule.file("classes" ) )
              .withFile( aardvarkModule.file("classes" ) ),
          :debug = true,
          :includeantruntime = false)
}

@Depends({"compileLauncher", "compileAardvark", "compileAardvarkTest"})
function compile() {
}

/*
 * Creates the aardvark jars
 */
@Depends({"jarLauncher", "jarAardvark"})
function jar() {
}

/*
 * Runs the tests
 */
@Depends("compile")
function test() {
  Ant.junit(:printsummary = Yes, :showoutput = false,
    :classpathBlocks = {
      \ p -> p.withFileset(rootDir.fileset("lib/ant/*.jar,lib/gosu/*.jar,lib/test/*.jar", null)),
      \ p -> p.withFile(launcherModule.file("classes")),
      \ p -> p.withFile(aardvarkModule.file("classes")),
      \ p -> p.withFile(aardvarkTestModule.file("classes"))
    }, :batchtestBlocks = {
      \ b -> {
        b.setHaltonerror(true)
        b.setHaltonfailure(true)
        b.addFileSet(aardvarkTestModule.file("classes").fileset("**/*Test.class", null))
      }
    })
}

/*
 * Creates the aardvark distribution
 */
@Depends("jar")
function dist() {
  Ant.mkdir(:dir = distDir)
  Ant.copy(
          :filesetList = { rootDir.fileset("LICENSE,bin/*,lib/ant/*,lib/gosu/*", null) },
          :todir = distDir)
  Ant.copy(
          :filesetList = { rootdir.fileset("*/dist/aardvark*.jar", null) },
          :todir = distDir.file("lib"),
          :flatten = true
  )
}

// TODO - GH-13 - dependency on test is temporarily disabled - run tests from IJ
@Depends({"clean", /*"test",*/ "dist"})
function release() {
  Ant.zip(:destfile = buildDir.file("aardvark.zip"), :zipfilesetList = { distDir.zipfileset(:prefix = "aardvark") })

  Ant.tar(:destfile = buildDir.file("aardvark.tar"), :tarfilesetBlocks = {
    \ tfs -> {
      tfs.Dir = distDir
      tfs.setIncludes("bin/vark,bin/vedit")
      tfs.setFileMode("755")
      tfs.setPrefix("aardvark")
    },
    \ tfs -> {
      tfs.Dir = distDir
      tfs.setExcludes("bin/vark,bin/vedit")
      tfs.setPrefix("aardvark")
    }
  })
  Ant.gzip(:src = buildDir.file("aardvark.tar"), :destfile = buildDir.file("aardvark.tgz"))
}

function clean() {
  Ant.delete( :dir = buildDir )
  Ant.delete( :dir = launcherModule.file("classes") )
  Ant.delete( :dir = launcherModule.file("dist") )
  Ant.delete( :dir = aardvarkModule.file("classes") )
  Ant.delete( :dir = aardvarkModule.file("dist") )
  Ant.delete( :dir = aardvarkTestModule.file("classes") )
  Ant.delete( :dir = aardvarkTestModule.file("dist") )
}
