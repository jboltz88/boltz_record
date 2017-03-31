module BoltzRecord
  class Collection < Array
    def update_all(updates)
      ids = self.map(&:id)
      self.any? ? self.first.class.update(ids, updates) : false
    end

    def take(num=1)
      ids = self.map(&:id)
      take_collection = Collection.new
      (0...num).each do |i|
        take_collection << self[i]
      end
      take_collection
    end

    def where(*args)
      ids = self.map(&:id)
      if args.count > 1
        expression = args.shift
        params = args
      else
        case args.first
        when String
          expression = args.first
        when Hash
          expression_hash = BoltzRecord::Utility.convert_keys(args.first)
          expression = expression_hash.map { |key, value| "#{key}=#{BoltzRecord::Utility.sql_strings(value)}"}.join(" AND ")
        end
      end
      if expression.nil?
        expression = "1 = 1"
      end
      # where("email = ? AND phone = ?", useremail, phone)
      string = "id IN (#{ids.join ","}) AND #{expression}"
      # WHERE id IN (1, 3, 5, ...)
      self.any? ? self.first.class.where(string) : false
    end

    def not(*args)
      ids = self.map(&:id)

      if args.count > 1
        expression = args.shift
        params = args
      else
        case args.first
        when String
          expression = args.first
        when Hash
          expression_hash = BoltzRecord::Utility.convert_keys(args.first)
          expression = expression_hash.map { |key, value| "NOT #{key} = #{BoltzRecord::Utility.sql_strings(value)}"}.join(" AND ")
        end
      end
      string = "id IN (#{ids.join ","}) AND #{expression}"
      self.any? ? self.first.class.where(string) : false
    end

    def destroy_all(*args)
      ids = self.map(&:id)
      if args.count > 1
        expression = args.shift
        params = args
      else
        case args.first
        when String
          expression = args.first
        when Hash
          expression_hash = BoltzRecord::Utility.convert_keys(args.first)
          expression = expression_hash.map { |key, value| "NOT #{key} = #{BoltzRecord::Utility.sql_strings(value)}"}.join(" AND ")
        end
        params = []
      end
      group = "id IN (#{ids.join ","}) AND #{expression}"
      params.unshift group
      self.any? ? self.first.class.destroy_all(*params) : false
    end

    def method_missing(method_name, *arguments, &block)
      if method_name.to_s =~ /update_(.*)/
        updates = {}
        updates[$1] = arguments[0]
        update_all(updates)
      else
        super
      end
    end
  end
end
