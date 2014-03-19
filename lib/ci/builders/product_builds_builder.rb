# encoding: UTF-8

# Copyright 2012-2013 Mikko Apo
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module Ki

  module Ci

    class CiProductsBuilder
      attr_chain :ki_home, :require

      def check(products, exceptions)
        products.each do |product_config|
          component_name = product_config["component"]
          exceptions.catch(component_name) do
            build_product(product_config, component_name)
          end
        end
      end

      def build_product(product_config, component_name)
        metadata = VersionMetadataFile.new("ki-version.json")
        new_deps = []
        version_lookup = {}
        # collect dependencies from config and generate new dependencies list
        old_deps = product_config.fetch("dependencies").map do |dep|
          tmp_dep = dep.dup
          tmp_dep["version_id"] = tmp_dep.delete("last_version")
          tmp_dep.delete("source")
          new_dep = tmp_dep.dup
          new_version_id = ki_home.version(dep["source"]).version_id
          version_lookup[dep["name"]] = new_version_id
          new_dep["version_id"] = new_version_id
          new_deps << new_dep
          tmp_dep
        end
        # if deps config has changes, import and create new version
        if (old_deps != new_deps)
          product_config.fetch("dependencies").each do |dep|
            dep["last_version"] = version_lookup[dep["name"]]
          end
          metadata.dependencies.concat(new_deps)
          metadata.save
          KiCommand.new.execute(%W(version-import -h #{ki_home.path} -f #{metadata.path} --move -c #{component_name}))
        end
      end
    end

    KiCommand.register("/ci/builders/products", CiProductsBuilder)
  end
end
