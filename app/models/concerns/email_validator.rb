class EmailValidator < ActiveModel::EachValidator
  def validate_each(instance, attr, value)
    unless value =~ /\A[A-Za-z0-9]((?!([^A-Za-z0-9])\1).){,62}[A-Za-z0-9]@(\w|\.|-){,253}\.[A-Za-z0-9]{2,}/
    #unless value =~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
      instance.errors.add(attr, (options[:message] || 'is not a valid email'))
    end
  end
end
