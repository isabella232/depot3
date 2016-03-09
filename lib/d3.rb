### Copyright 2016 Pixar
###
###    Licensed under the Apache License, Version 2.0 (the "Apache License")
###    with the following modification; you may not use this file except in
###    compliance with the Apache License and the following modification to it:
###    Section 6. Trademarks. is deleted and replaced with:
###
###    6. Trademarks. This License does not grant permission to use the trade
###       names, trademarks, service marks, or product names of the Licensor
###       and its affiliates, except as required to comply with Section 4(c) of
###       the License and to reproduce the content of the NOTICE file.
###
###    You may obtain a copy of the Apache License at
###
###        http://www.apache.org/licenses/LICENSE-2.0
###
###    Unless required by applicable law or agreed to in writing, software
###    distributed under the Apache License with the above modification is
###    distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
###    KIND, either express or implied. See the Apache License for the specific
###    language governing permissions and limitations under the Apache License.
###
###

#####################################
# Required Libraries, etc
#####################################

###################
# gems

require 'ruby-jss'
require 'keychain'

###################
# Standard Libraries
require 'English'
require 'logger'
require 'pathname'
require 'plist'
require 'tempfile'
require 'shellwords'
require 'open-uri'
require 'yaml'
require 'readline'
require 'io/console'
require 'ostruct'
require 'getoptlong'

###################
# Our classes and submodules

# Order Matters!
require 'd3/version'
require 'd3/constants'
require 'd3/exceptions'
require 'd3/configuration'
require 'd3/log'
require 'd3/state'
require 'd3/utility'
require 'd3/database'
require 'd3/basename'
require 'd3/package'
require 'd3/admin'
require 'd3/client'
require 'd3/puppytime'


module D3

  ### we're loaded!
  @@loaded = true

  # Start logging
  D3.log "D3 module loaded, logging started", :debug

end # module D3


