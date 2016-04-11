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
  class Package < JSS::Package

    ################# Constructor #################

    ###  Existing d3 pkgs are looked up by providing :id, :name,
    ### :basename, :edition, or the combination of
    ### :basename, :version, and :revision (which comprise the edition)
    ###
    ### If passed only a :basename, the currently-live package for that basename
    ###  is used, an exception is raised if no version of the basename is live.
    ###
    ### When creating a new d3 package use :id => :new, as for JSS::Package.
    ### You must provide :name, :basename, :version, and :revision.
    ###
    ### To add a pkg to d3 that's already in the JSS, use {D3::Package.import} (q.v.)
    ###
    ### For new (or imported) packages, you may also provide any of the other
    ###   data keys mentioned in P_FIELDS.keys and they will be applied to the
    ###   new Package. You may also set them after instantiation using their
    ###   respective setter methods. A value for :admin must be set before
    ###   calling {#create}.
    ###
    def initialize (args={})

      # refresh our pkg data first
      D3::Package.package_data :refresh

      # if we didn't get an edition, did we get the parts?
      if args[:basename] && args[:version] && args[:revision]
        args[:edition] ||= "#{args[:basename]}-#{args[:version]}-#{args[:revision]}"
      end
      args[:category] ||= D3::CONFIG.jss_default_pkg_category

      ############ Adding a New d3/jss package
      if args[:id] == :new

        # make sure we have the needed args
        unless args[:basename] and args[:version] and args[:revision]
          raise JSS::MissingDataError, "New d3 packages need :basename, :version, & :revision."
        end

        # does the edition we're creating already exist?
        if D3::Package.all_editions.include? args[:edition]
          raise JSS::AlreadyExistsError, "Package edition #{args[:edition]} already exists in d3"
        end

        @adding = true

      ############ Importing an existing JSS pkg?
      elsif args[:import]

        # args[:import] should only ever come from D3::Package.import
        # in ruby 1.8 use caller[1][/`([^']*)'/, 1] to get the label 'import'
        # doesn't matter since JSS now requires ruby 1.9.2
        raise JSS::InvalidDataError, "Use D3::Package.import to import existing JSS packages to d3." unless caller_locations(2,1)[0].label == "import"


        # data checking was done in the import class method
        @importing = true

      ############ Looking up an existing package by id, name, basename, or edition
      else
        if args[:id]
          status =  D3::Package.statuses_by(:id)[args[:id]]
          if status
            @status = :missing if status == :missing
          else
            raise JSS::NoSuchItemError, "No package in d3 with id: #{args[:id]}"
          end

        elsif args[:name]
          status =  D3::Package.statuses_by(:name)[args[:name]]
          if status
            @status = :missing if status == :missing
            args[:id] = JSS::Package.map_all_ids_to(:name).invert[args[:name]]
          else
            raise JSS::NoSuchItemError, "No package in d3 with name: #{args[:name]}"
          end


        elsif args[:edition]
          status =  D3::Package.statuses_by(:edition)[args[:edition]]
          if status
            @status = :missing if status == :missing
            args[:id] = D3::Package.ids_to_editions.invert[ args[:edition]]
          else
            raise JSS::NoSuchItemError, "No package in d3 with edition: #{args[:edition]}"
          end


        elsif args[:basename]
          args[:id] = D3::Package.basenames_to_live_ids[args[:basename]]
          raise JSS::NoSuchItemError, "No live package for basename '#{args[:basename]}'" unless args[:id]
        end # if args :id

        @lookup_existing = true

      end # if args[:id] == :new

      # if the pkg is missing from the jss, there's nothing to do below here
      return if @status == :missing

      # now we have an :id (which might be :new) so let JSS::Package do its work
      # this will tie us to a new or existing jss pkg
      super args

      # does this pkg need to be added to d3?
      if @adding or @importing

        d3pkg_data = args
        @status = :unsaved
        @in_d3 = false

      else # package already exists in both JSS and d3...

        # This prevents some checks from happening, since the data came from the DB
        @initializing = true
        d3pkg_data = D3::Package.package_data(:refresh)[@id]
        @in_d3 = true

      end # if  @adding or @importing

      @basename = d3pkg_data[:basename]
      @version = d3pkg_data[:version]
      @revision = d3pkg_data[:revision]

      # process the d3 data
      if d3pkg_data

        # Loop through the field definitions for the pkg table and process each one
        # into it's ruby attribute.
        P_FIELDS.each do |fld_key, fld_def|

          # skip if we already have a value, e.g. basename was set above.
          next if self.send(fld_key)

          # Note - the d3pkgdata has already been 'rubyized' via the D3::Database.table_records method
          # (which was used by D3::Package.package_data)
          fld_val = d3pkg_data[fld_key]

          # if we have a setter method for this key, call it to set the attribute.
          setter = "#{fld_key}=".to_sym
          send(setter, fld_val) if self.respond_to?(setter, true)  # the 'true' makes respond_to? look at private methods also

        end # PFIELDS.each
      end # if d3pkg_data

      # some nil-values shouldn't be nil
      @auto_groups ||= []
      @excluded_groups ||= []

      # these don't come from the table def.
      @admin = args[:admin]

      # dmg or pkg?
      @package_type = @receipt.to_s.end_with?(".dmg") ? :dmg : :pkg

      # this needs to be an array
      @apple_receipt_data ||= []

      # re-enable checks
      @initializing = false

    end # init
  end # class Package
end # module D3
