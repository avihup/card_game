puts "🎮 Starting Card Games API seeds..."

# Clear existing data
puts "🧹 Clearing existing data..."
GameSession.destroy_all
GameRule.destroy_all

# Create default game rules
puts "🎯 Creating default game rules..."
result = GameRulesService.create_default_game_templates

if result.success?
  puts "✅ Created #{result.data.count} default game templates:"
  result.data.each do |game_rule|
    puts "  - #{game_rule.name} (#{game_rule.player_range})"
  end
else
  puts "❌ Failed to create default templates: #{result.errors.join(', ')}"
end

# Create some example custom game rules
puts "🎲 Creating custom game rules..."

custom_rules = [
  {
    name: "Speed Cards",
    description: "Fast-paced card matching game",
    deck_size: 52,
    min_players: 2,
    max_players: 4,
    rules_data: {
      initial_hand_size: 5,
      win_condition: "first_to_empty_hand",
      turn_actions: ["play_card", "draw_card"],
      special_rules: {
        simultaneous_play: true,
        no_turn_order: true
      },
      scoring: {
        type: "elimination",
        points: {}
      }
    },
    created_by: "system",
    version: "1.0"
  },
  {
    name: "Memory Match",
    description: "Card memory and matching game",
    deck_size: 52,
    min_players: 2,
    max_players: 6,
    rules_data: {
      initial_hand_size: 0,
      win_condition: "most_sets",
      turn_actions: ["flip_card", "match_cards"],
      special_rules: {
        memory_game: true,
        face_down_cards: true
      },
      scoring: {
        type: "sets",
        points: { "pair": 1, "three_of_kind": 3, "four_of_kind": 5 }
      }
    },
    created_by: "system",
    version: "1.0"
  }
]

custom_rules.each do |rule_data|
  result = GameRulesService.create_game_rule(rule_data)
  if result.success?
    puts "  ✅ Created: #{result.data.name}"
  else
    puts "  ❌ Failed to create #{rule_data[:name]}: #{result.errors.join(', ')}"
  end
end

# Print summary
puts "\n📊 Database Summary:"
puts "  Game Rules: #{GameRule.count} (#{GameRule.active.count} active)"
puts "  Game Sessions: #{GameSession.count}"
puts "  Game Players: #{GamePlayer.count}"

puts "\n🎉 Seeds completed successfully!"
puts "\n🔍 To explore the API:"
puts "  • Health check: GET /api/v1/health"
puts "  • List games: GET /api/v1/game_rules?user_id=test123"
puts "  • API docs: http://localhost:3000/api-docs"
puts "  • Create game: POST /api/v1/game_sessions"
puts "\n📚 Don't forget to check the Swagger documentation at /api-docs!"
