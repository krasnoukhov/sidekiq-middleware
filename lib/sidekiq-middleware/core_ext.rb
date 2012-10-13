class Hash
  def slice(*items)
    items = items.to_a.flatten

    {}.tap do |hash|
      items.each do |item|
        hash[item] = self[item] if self[item]
      end
    end
  end
end