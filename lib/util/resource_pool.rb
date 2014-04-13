module Ki

  class ResourcePoolState < KiJSONHashFile

  end

  class ResourcePool < KiJSONHashFile
    attr_chain :state, -> { ResourcePoolState.new(File.basename(path).gsub(".json", "")+"-state.json").parent(parent) }

    # returns a reservation key that can be claimed
    def claim_for_other(duration, id)
      random_claim_id = rand(9999999).to_s
      claimed = lock_one({
                   "claimed_for" => id,
                   "until" => Time.now.to_f + duration,
                   "claim_id" => random_claim_id
               })
      if claimed
        "#{claimed}:#{random_claim_id}"
      end
    end

    def reserve(id)
      lock_one({
                   "reserved_for" => id,
                   "start" => Time.now.to_f
               })
    end

    def reserve_claim(id, claim_key)
      key, claim_id = claim_key.split(":")
      if !cached_data.include?(key)
        raise "Resource #{key} does not exist!"
      end
      state.edit_data do |resource_state|
        res = resource_state.cached_data[key]
        if res.nil?
          raise "Resource #{key} not claimed!"
        end
        if res["claim_id"] != claim_id
          raise "Resource #{key} claimed with id #{claim_id} different from #{res["claim_id"]}!"
        end
        now = Time.now.to_f
        if res["until"] < now
          raise "Claim for resource #{key} claimed with id #{claim_id} is too old (now: #{now} until: #{res["until"]}!"
        end
        res["reserved_for"]=id
        res["start"] = Time.now.to_f
      end
      key
    end

    def lock_one(info)
      ret = nil
      state.edit_data do |resource_state|
        reload.cached_data.keys.each do |key|
          if !resource_state.cached_data.include?(key)
            resource_state.cached_data[key]= info
            ret = key
            break
          end
        end
      end
      ret
    end

    def free(key, id)
      key, claim_id = key.split(":")
      state.edit_data do |resource_state|
        resource = resource_state.cached_data[key]
        if resource
          if resource["reserved_for"]!=id
            if resource["claimed_for"]
              raise "Can't free resource #{key}. It's claimed for '#{resource["claimed_for"]}'!"
            else
              raise "Can't free resource #{key}. It's reserved for '#{resource["reserved_for"]}' and #{id} tried to free it!"
            end
          end
          resource_state.cached_data.delete(key)
        end
      end
    end

    def clean
      # remove outdated claims
      # check reserved items
    end
  end

end
