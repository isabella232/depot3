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


module D3

  module Admin
    module Prefs
      extend self
      ################# Admin User Prefs #################

      ################# Module Constants #################

      PREFS_DIR = Pathname.new(ENV['HOME'].to_s).expand_path + "Library/Preferences"
      PREFS_FILE = PREFS_DIR + "com.pixar.d3.admin.yaml"

      PREF_KEYS = {
        workspace: {
          klass: Pathname,
          description: "Path to the directory where new pkg and dmg packages are built.\n If unset, defaults to your home folder"
        },
        apple_pkg_id_prefix: {
          klass: String,
          description: "The Apple package id prefix, e.g. 'com.mycompany'.\nWhen .pkgs are built, the identifier will be this, plus the basename.\n If unset, the default is '#{D3::Admin::DFT_PKG_ID_PREFIX}'"
        },
        last_config: {
          klass: Time,
          description: "Timestamp of the last configuration for setting servers, credentials and/or prefs"
        }
      }

      @@prefs = PREFS_FILE.readable? ? YAML.load(PREFS_FILE.read) : {}

      ### Return a hash of prefs for this admin
      ###
      ### @return [Hash] the d3admin prefs for the current user
      ###
      def prefs
        @@prefs
      end

      ### Set a pref and save the change
      ###
      ### @param pref[Symbol] the pref to set, one of the keys of PREF_KEYS
      ###
      ### @param value[Object] the value to save with the pref
      ###
      ### @return [Boolean] true of the pref was set and saved
      def set_pref (pref, value)
        raise JSS::InvalidDataError, "first argument must be a pref key from D3::Admin::Prefs::PREF_KEYS" unless PREF_KEYS.keys.include? pref
        @@prefs[pref] = value
        save_prefs
      end

      ### Save the current prefs to disk for this user
      ###
      ### @return [void]
      def save_prefs
        @@prefs[:last_config] =  Time.now
        PREFS_FILE.jss_save YAML.dump(@@prefs)
      end

    end # module prefs
  end # module Admin
end # module D3

