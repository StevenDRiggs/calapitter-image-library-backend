class UrlValidator < ActiveModel::EachValidator
  def validate_each(instance, attr, value)
    unless value =~ /https?:\/\/[A-Za-z]\w*\.[A-Za-z]{2,}(\/.*|\?.*)?/
      instance.errors.add(attr, (options[:message] || 'is not a valid url'))
    end
  end
end
