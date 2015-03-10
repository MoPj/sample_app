module GravatarHelper  
          module PublicMethods
            AVATAR_SIZES = [25, 50, 70]
        
            def gravatar_for_with_default(object, options={})
             options[:size] ||= 25      
             options.merge!(:default =>  "http://www.whatiwantforxmas.com/images/avatars/santa/santa-#{options[:size]}.png")      
             # sizes are 25, 50 and 70
             raise RuntimeError, "Incorrect size for Avatar" \
                 unless AVATAR_SIZES.index(options[:size])    
             gravatar_for_without_default(object, options)
           end
           alias_method_chain :gravatar_for, :default
        end  
        end  