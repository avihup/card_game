class DeckGeneratorService
  class << self
    def generate_deck(rules_data)
      deck_config = rules_data['deck_configuration'] || {}
      
      raise ArgumentError, "deck_configuration is required in rules_data" unless deck_config.present?
      raise ArgumentError, "deck_configuration must include cards array" unless deck_config['cards']&.is_a?(Array)
      
      deck = []
      card_id_counter = 1
      
      deck_config['cards'].each do |card_definition|
        count = card_definition['count'] || 1
        
        count.times do
          card = build_card_from_definition(card_definition, card_id_counter)
          deck << card
          card_id_counter += 1
        end
      end
      
      # Apply deck-level transformations
      deck = apply_deck_transformations(deck, deck_config, card_id_counter)
      
      # Shuffle if configured (default: true)
      should_shuffle = deck_config.fetch('shuffle', true)
      should_shuffle ? deck.shuffle : deck
    end

    private

    def build_card_from_definition(card_def, card_id)
      {
        id: card_id,
        suit: card_def['suit'] || 'default',
        rank: card_def['rank'] || 'unknown',
        value: card_def['value'] || 0,
        color: card_def['color'] || 'default',
        type: card_def['type'] || 'basic',
        display_name: card_def['display_name'] || "#{card_def['rank']} of #{card_def['suit']}",
        properties: card_def['properties'] || {}
      }
    end

    def apply_deck_transformations(deck, deck_config, card_id_counter)
      transformations = deck_config['transformations'] || []
      
      transformations.each do |transformation|
        case transformation['type']
        when 'duplicate_subset'
          deck, card_id_counter = duplicate_subset(deck, transformation, card_id_counter)
        when 'add_jokers'
          deck, card_id_counter = add_jokers(deck, transformation, card_id_counter)
        when 'custom_mapping'
          deck = apply_custom_mapping(deck, transformation)
        end
      end
      
      deck
    end

    def duplicate_subset(deck, transformation, card_id_counter)
      criteria = transformation['criteria'] || {}
      times = transformation['times'] || 1
      
      subset = deck.select do |card|
        matches_criteria?(card, criteria)
      end
      
      times.times do
        subset.each do |original_card|
          new_card = original_card.dup
          new_card[:id] = card_id_counter
          deck << new_card
          card_id_counter += 1
        end
      end
      
      [deck, card_id_counter]
    end

    def add_jokers(deck, transformation, card_id_counter)
      count = transformation['count'] || 2
      joker_def = transformation['joker_definition'] || {
        'suit' => 'joker',
        'rank' => 'joker',
        'value' => 50,
        'color' => 'red',
        'type' => 'wild'
      }
      
      count.times do
        deck << build_card_from_definition(joker_def, card_id_counter)
        card_id_counter += 1
      end
      
      [deck, card_id_counter]
    end

    def apply_custom_mapping(deck, transformation)
      mapping = transformation['mapping'] || {}
      
      deck.map do |card|
        mapped_values = mapping[card[:rank]] || mapping[card[:suit]] || {}
        card.merge(mapped_values)
      end
    end

    def matches_criteria?(card, criteria)
      criteria.all? do |key, value|
        case value
        when Array
          value.include?(card[key.to_sym])
        when String, Integer
          card[key.to_sym] == value
        else
          false
        end
      end
    end
  end
end 