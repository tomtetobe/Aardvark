/*
 * Copyright (c) 2012 Guidewire Software, Inc.
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

package gw.vark

uses org.apache.tools.ant.Project
uses org.apache.tools.ant.Target

enhancement CoreProjectEnhancement : Project {

  function registerTarget(name : String, op() : void) : Target {
    var target = new Target() {
      override function execute() {
        if (op != null) {
          op()
        }
      }
    }
    target.Name = name
    AardvarkProgram.getInstance(this).RuntimeGeneratedTargets.add(target);
    return target
  }

}
