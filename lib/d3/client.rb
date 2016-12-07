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


###
module D3

  ### This class represents a d3 client, a computer managed
  ### by the JSS which hosts d3, as well as the d3
  ### cli client program running on that computer.
  ###
  class Client < JSS::Client

    ### Default notification_image_path
    ### Unless otherwise specified in /etc/d3.conf,
    ### this is the default directory that can be populated
    ### with image(s) to display randomly alongside user notifications.

    DFT_NOTIFICATION_IMAGE_PATH = D3::SUPPORT_DIR + "notification_images"

  end # class Client
end # module D3

require "d3/client/class_variables"
require "d3/client/class_methods"
require "d3/client/receipt"
require "d3/client/environment"
require "d3/client/auth"
require "d3/client/cli"
require "d3/client/lists"
require "d3/client/help"
