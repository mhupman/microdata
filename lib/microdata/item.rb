module Microdata
  class Item
    attr_reader :type, :properties, :id

    def initialize(top_node, page_url)
      @top_node = top_node
      @type = extract_itemtype
      @id   = extract_itemid
      @properties = {}
      @page_url = page_url
      add_itemref_properties(@top_node)
      parse_elements(extract_elements(@top_node))
    end

    def to_hash
      hash = {}
      hash[:id] = id if id
      hash[:type] = type if type
      hash[:properties] = {}
      properties.each do |name, values|
        final_values = values.map do |value|
          if value.is_a?(Item)
            value.to_hash
          else
            value
          end
        end
        hash[:properties][name] = final_values
      end
      hash
    end

    private

    def extract_elements(node)
      node.search('./*')
    end

    def extract_itemid
      (value = @top_node.attribute('itemid')) ? value.value : nil
    end

    def extract_itemtype
      (value = @top_node.attribute('itemtype')) ? value.value.split(' ') : nil
    end

    def parse_elements(elements)
      elements.each {|element| parse_element(element)}
    end

    def parse_element(element)
      itemscope = element.attribute('itemscope')
      itemprop = element.attribute('itemprop')
      internal_elements = extract_elements(element)
      add_itemprop(element) if itemscope || itemprop
      parse_elements(internal_elements) if internal_elements && !itemscope
    end

    # Add an 'itemprop' to the properties
    def add_itemprop(itemprop)
      properties = Itemprop.parse(itemprop, @page_url)
      properties.each { |name, value| (@properties[name] ||= []) << value }
    end

    # Add any properties referred to by 'itemref'
    def add_itemref_properties(element)
      itemref = element.attribute('itemref')
      if itemref
        itemref.value.split(' ').each {|id| parse_elements(find_with_id(id))}
      end
    end

    # Find an element with a matching id
    def find_with_id(id)
      @top_node.search("//*[@id='#{id}']")
    end

  end
end