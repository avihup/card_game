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
    name: "Simple Number Cards",
    description: "Simple card game with custom number cards",
    deck_size: 20,
    min_players: 2,
    max_players: 4,
    rules_data: {
      initial_hand_size: 5,
      win_condition: "first_to_empty_hand",
      turn_actions: ["play_card", "draw_card"],
      deck_configuration: {
        description: "Simple deck with numbered cards 1-5 in 4 colors",
        cards: [
          { suit: "red", rank: "1", value: 1, color: "red", type: "number", count: 1 },
          { suit: "red", rank: "2", value: 2, color: "red", type: "number", count: 1 },
          { suit: "red", rank: "3", value: 3, color: "red", type: "number", count: 1 },
          { suit: "red", rank: "4", value: 4, color: "red", type: "number", count: 1 },
          { suit: "red", rank: "5", value: 5, color: "red", type: "number", count: 1 },
          { suit: "blue", rank: "1", value: 1, color: "blue", type: "number", count: 1 },
          { suit: "blue", rank: "2", value: 2, color: "blue", type: "number", count: 1 },
          { suit: "blue", rank: "3", value: 3, color: "blue", type: "number", count: 1 },
          { suit: "blue", rank: "4", value: 4, color: "blue", type: "number", count: 1 },
          { suit: "blue", rank: "5", value: 5, color: "blue", type: "number", count: 1 },
          { suit: "green", rank: "1", value: 1, color: "green", type: "number", count: 1 },
          { suit: "green", rank: "2", value: 2, color: "green", type: "number", count: 1 },
          { suit: "green", rank: "3", value: 3, color: "green", type: "number", count: 1 },
          { suit: "green", rank: "4", value: 4, color: "green", type: "number", count: 1 },
          { suit: "green", rank: "5", value: 5, color: "green", type: "number", count: 1 },
          { suit: "yellow", rank: "1", value: 1, color: "yellow", type: "number", count: 1 },
          { suit: "yellow", rank: "2", value: 2, color: "yellow", type: "number", count: 1 },
          { suit: "yellow", rank: "3", value: 3, color: "yellow", type: "number", count: 1 },
          { suit: "yellow", rank: "4", value: 4, color: "yellow", type: "number", count: 1 },
          { suit: "yellow", rank: "5", value: 5, color: "yellow", type: "number", count: 1 }
        ]
      },
      card_play_rules: {
        play_rules: [
          { type: "match_any_properties", properties: ["color", "rank"] }
        ]
      },
      scoring: {
        type: "elimination",
        points: {}
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
