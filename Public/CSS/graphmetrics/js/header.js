/*******************************************************************************
 * Copyright 2017 IBM Corp.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *******************************************************************************/
function updateHeader(data) {
  var titleAndDocs = JSON.parse(data);
  if (titleAndDocs.hasOwnProperty('title'))
    d3.select('.leftHeader')
      .text(titleAndDocs.title);
  if (titleAndDocs.hasOwnProperty('docs')) {
    d3.select('.rightHeader')
      .select('.docLink')
      .remove();
    d3.select('.rightHeader').append('a')
      .attr('class', 'docLink')
      .attr('href', titleAndDocs.docs)
      .text('Go To Documentation');
  }
}
