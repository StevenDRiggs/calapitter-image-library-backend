class ProfanityFilterValidator < ActiveModel::EachValidator
  def validate_each(instance, attr, value)
    pf = ProfanityFilter.new
    if pf.profane?(value, strategies: :all)
      instance.errors[attr] << (options[:message] || 'cannot include profanity')
    end
  end
end
