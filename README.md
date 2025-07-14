# Card Games API 🎮

A Ruby on Rails API application that manages card game rules internally and enables multiplayer card games through RESTful endpoints.

## 🚀 Features

- **Game Rules Management**: Create, read, update, and delete game rules
- **Game Session Management**: Create and manage multiplayer game sessions
- **Player Management**: Handle player joining, leaving, and turn management
- **Real-time Gameplay**: Turn-based gameplay with move validation
- **Swagger Documentation**: Complete API documentation at `/api-docs`
- **MongoDB Storage**: Flexible document storage for game data

## 🏗️ Architecture

### Technology Stack
- **Backend**: Ruby on Rails 8.0 (API-only)
- **Database**: MongoDB with Mongoid ODM
- **Authentication**: Simple user_id/username (JWT integration ready)
- **Documentation**: Swagger/OpenAPI 3.0
- **Testing**: RSpec (configured)

### Core Components

#### Models
- `GameRule`: Stores game definitions and rules
- `GameSession`: Represents active game instances
- `GamePlayer`: Player participation in specific games

#### Services
- `GameRulesService`: Handles game rule creation and validation
- `GameSessionService`: Manages game lifecycle
- `GameEngineService`: Processes game-specific logic and move validation

#### Controllers
- `GameRulesController`: Game rules management endpoints
- `GameSessionsController`: Game session management endpoints
- `HealthController`: API health check endpoint

## 🚦 Getting Started

### Prerequisites
- Ruby 3.3+
- MongoDB (running locally on default port 27017)
- Bundle gem

### Installation

1. **Clone and install dependencies**:
```bash
git clone <repository-url>
cd card_games
bundle install
```

2. **Start MongoDB** (if not already running):
```bash
mongod
```

3. **Seed the database**:
```bash
rails db:seed
```

4. **Start the server**:
```bash
rails server
```

The API will be available at `http://localhost:3000/api/v1`

## 📚 API Documentation

### Base URL
- **Development**: `http://localhost:3000/api/v1`
- **Swagger UI**: `http://localhost:3000/api-docs`

### Authentication
For now, authentication is simplified using:
- **Query Parameter**: `user_id=YOUR_USER_ID`
- **Header**: `X-User-Id: YOUR_USER_ID`

## 🎯 API Endpoints

### Game Rules Management

#### List Game Rules
```bash
GET /api/v1/game_rules?user_id=test123
```

#### Get Specific Game Rule
```bash
GET /api/v1/game_rules/:id?user_id=test123
```

#### Create Game Rule
```bash
POST /api/v1/game_rules?user_id=test123
Content-Type: application/json

{
  "game_rule": {
    "name": "My Custom Game",
    "description": "A custom card game",
    "min_players": 2,
    "max_players": 4,
    "deck_size": 52,
    "rules_data": {
      "initial_hand_size": 7,
      "win_condition": "first_to_empty_hand",
      "turn_actions": ["play_card", "draw_card"],
      "special_rules": {},
      "scoring": {
        "type": "elimination",
        "points": {}
      }
    }
  }
}
```

### Game Session Management

#### Create Game Session
```bash
POST /api/v1/game_sessions?user_id=player1&username=Player1
Content-Type: application/json

{
  "game_session": {
    "game_rule_id": "GAME_RULE_ID"
  }
}
```

#### Join Game Session
```bash
POST /api/v1/game_sessions/:id/join?user_id=player2&username=Player2
```

#### Start Game Session
```bash
POST /api/v1/game_sessions/:id/start?user_id=player1
```

#### Play Turn
```bash
POST /api/v1/game_sessions/:id/play_turn?user_id=player1
Content-Type: application/json

{
  "play_turn": {
    "action": "play_card",
    "card_id": 1
  }
}
```

#### Get Game State
```bash
GET /api/v1/game_sessions/:id?user_id=player1
```

## 🎮 Example Game Flow

### 1. Create a Game Session
```bash
# Player 1 creates a game
curl -X POST "http://localhost:3000/api/v1/game_sessions?user_id=player1&username=Player1" \
  -H "Content-Type: application/json" \
  -d '{
    "game_session": {
      "game_rule_id": "GAME_RULE_ID"
    }
  }'
```

### 2. Player 2 Joins
```bash
curl -X POST "http://localhost:3000/api/v1/game_sessions/SESSION_ID/join?user_id=player2&username=Player2"
```

### 3. Start the Game
```bash
curl -X POST "http://localhost:3000/api/v1/game_sessions/SESSION_ID/start?user_id=player1"
```

### 4. Players Take Turns
```bash
# Player 1 plays a card
curl -X POST "http://localhost:3000/api/v1/game_sessions/SESSION_ID/play_turn?user_id=player1" \
  -H "Content-Type: application/json" \
  -d '{
    "play_turn": {
      "action": "play_card",
      "card_id": 1
    }
  }'
```

## 🎲 Built-in Game Templates

The system comes with flexible, configuration-driven game templates:

1. **Standard Card Game** - Basic card game with traditional 52-card deck (2-6 players)
2. **TAKI** - Fully configurable Israeli card game with custom deck and rules (2-10 players)
3. **Simple Number Cards** - Example of a custom deck with colored number cards (2-4 players)

All games are completely customizable through the configuration system - no hardcoded game logic!

## 🔧 Game Rule Structure

Game rules are defined using a flexible JSON structure that allows complete customization:

```json
{
  "name": "My Custom Card Game",
  "description": "A fully customizable card game",
  "min_players": 2,
  "max_players": 4,
  "deck_size": 20,
  "rules_data": {
    "initial_hand_size": 5,
    "win_condition": "first_to_empty_hand",
    "turn_actions": ["play_card", "draw_card", "custom_action"],
    "deck_configuration": {
      "description": "Custom deck description",
      "cards": [
        {
          "suit": "red",
          "rank": "1",
          "value": 1,
          "color": "red",
          "type": "number",
          "count": 2,
          "display_name": "Red One",
          "properties": {
            "special": false
          }
        }
      ],
      "transformations": [
        {
          "type": "duplicate_subset",
          "criteria": { "type": "action" },
          "times": 1
        }
      ]
    },
    "card_play_rules": {
      "play_rules": [
        { "type": "match_any_properties", "properties": ["color", "rank"] },
        { "type": "always_playable", "criteria": { "type": "wild" } }
      ],
      "special_effects": [
        {
          "criteria": { "rank": "skip" },
          "type": "skip_player",
          "message": "Next player is skipped!"
        }
      ]
    },
    "custom_actions": {
      "power_play": {
        "description": "Play multiple cards at once",
        "requirements": [
          { "type": "hand_size", "minimum": 3 }
        ],
        "state_changes": { "power_mode": true }
      }
    },
    "scoring": {
      "type": "points",
      "points": {
        "1": 1,
        "wild": 50,
        "default": 5
      }
    }
  }
}
```

### Deck Configuration

The `deck_configuration` section allows you to define exactly what cards are in your deck:

#### Card Definition
- `suit`: The suit/category of the card
- `rank`: The rank/name of the card
- `value`: Numerical value for scoring
- `color`: Visual color of the card
- `type`: Type category (number, action, wild, special, etc.)
- `count`: How many of this card to include
- `display_name`: How the card appears to players
- `properties`: Custom properties for special rules

#### Deck Transformations
- `duplicate_subset`: Duplicate cards matching certain criteria
- `add_jokers`: Add joker cards to the deck
- `custom_mapping`: Apply custom transformations to cards

### Card Play Rules

The `card_play_rules` section defines how cards can be played:

#### Play Rule Types
- `match_property`: Card must match a specific property of the last played card
- `match_any_properties`: Card must match any of the specified properties
- `match_all_properties`: Card must match all specified properties
- `always_playable`: Cards matching criteria can always be played
- `conditional`: Complex conditional rules based on game state

#### Special Effects
Define what happens when certain cards are played:
- `skip_player`: Skip the next player's turn
- `reverse_direction`: Reverse the direction of play
- `force_draw`: Make players draw cards
- `custom_effect`: Apply custom game state changes

### Custom Actions

Define completely custom turn actions beyond the basic play/draw:

```json
"custom_actions": {
  "trade_cards": {
    "description": "Trade cards with another player",
    "requirements": [
      { "type": "has_card", "criteria": { "type": "trade" } }
    ],
    "state_changes": { "trading_phase": true }
  }
}
```

### Win Conditions
- `first_to_empty_hand`: First player to empty their hand wins
- `highest_score`: Player with highest score wins
- `lowest_score`: Player with lowest score wins
- `last_player_standing`: Last active player wins

### Turn Actions
You can define any custom turn actions. Common ones include:
- `play_card`: Play a card from hand
- `draw_card`: Draw a card from deck
- `pass`: Pass the turn
- `discard`: Discard a card
- Custom actions defined in `custom_actions`

### Scoring Systems
- `elimination`: First to empty hand wins (no scoring)
- `points`: Point-based scoring with custom point values
- `sets`: Score based on collecting sets of cards
- `custom`: Define your own scoring logic

### Card IDs and Gameplay

Each card in the deck gets a unique ID when the deck is generated. When players receive cards in their hand, they can reference specific cards by their ID rather than by position in hand. This makes gameplay more robust as hand order may change.

#### Playing Cards by ID
When making a `play_card` action, use the card's unique ID:

```json
{
  "action": "play_card",
  "card_id": 42
}
```

#### Card Structure
Each card in a player's hand includes:
```json
{
  "id": 42,
  "suit": "red",
  "rank": "5", 
  "value": 5,
  "color": "red",
  "type": "number",
  "display_name": "5 of red",
  "properties": {}
}
```

## 🎯 Example: Creating a TAKI Game

Here's a complete example of how to create a TAKI game using the configuration system:

```bash
POST /api/v1/game_rules?user_id=creator123
Content-Type: application/json

{
  "game_rule": {
    "name": "My Custom TAKI",
    "description": "Israeli card game with custom rules",
    "deck_size": 56,
    "min_players": 2,
    "max_players": 8,
    "rules_data": {
      "initial_hand_size": 8,
      "win_condition": "first_to_empty_hand",
      "turn_actions": ["play_card", "draw_card", "taki_sequence", "change_color"],
      
      "deck_configuration": {
        "description": "TAKI deck with colored cards and special actions",
        "cards": [
          { "suit": "red", "rank": "1", "value": 1, "color": "red", "type": "number", "count": 2 },
          { "suit": "red", "rank": "2", "value": 2, "color": "red", "type": "number", "count": 2 },
          { "suit": "red", "rank": "3", "value": 3, "color": "red", "type": "number", "count": 2 },
          { "suit": "red", "rank": "4", "value": 4, "color": "red", "type": "number", "count": 2 },
          { "suit": "red", "rank": "5", "value": 5, "color": "red", "type": "number", "count": 2 },
          { "suit": "red", "rank": "stop", "value": 25, "color": "red", "type": "action", "count": 2 },
          { "suit": "red", "rank": "plus", "value": 10, "color": "red", "type": "action", "count": 2 },
          { "suit": "red", "rank": "taki", "value": 30, "color": "red", "type": "action", "count": 2 },
          { "suit": "blue", "rank": "1", "value": 1, "color": "blue", "type": "number", "count": 2 },
          { "suit": "blue", "rank": "2", "value": 2, "color": "blue", "type": "number", "count": 2 },
          { "suit": "blue", "rank": "3", "value": 3, "color": "blue", "type": "number", "count": 2 },
          { "suit": "blue", "rank": "4", "value": 4, "color": "blue", "type": "number", "count": 2 },
          { "suit": "blue", "rank": "5", "value": 5, "color": "blue", "type": "number", "count": 2 },
          { "suit": "blue", "rank": "stop", "value": 25, "color": "blue", "type": "action", "count": 2 },
          { "suit": "blue", "rank": "plus", "value": 10, "color": "blue", "type": "action", "count": 2 },
          { "suit": "blue", "rank": "taki", "value": 30, "color": "blue", "type": "action", "count": 2 },
          { "suit": "special", "rank": "super_taki", "value": 50, "color": "black", "type": "wild", "count": 2 },
          { "suit": "special", "rank": "king", "value": 50, "color": "black", "type": "wild", "count": 2 },
          { "suit": "special", "rank": "plus_three", "value": 30, "color": "black", "type": "special", "count": 2 },
          { "suit": "wild", "rank": "change_color", "value": 30, "color": "black", "type": "wild", "count": 4 }
        ]
      },
      
      "card_play_rules": {
        "play_rules": [
          { "type": "match_any_properties", "properties": ["color", "rank"] },
          { "type": "always_playable", "criteria": { "type": "wild" } },
          { "type": "always_playable", "criteria": { "rank": "super_taki" } },
          { "type": "always_playable", "criteria": { "rank": "king" } }
        ],
        "special_effects": [
          {
            "criteria": { "rank": "stop" },
            "type": "skip_player",
            "message": "Next player is skipped!"
          },
          {
            "criteria": { "rank": "plus_three" },
            "type": "force_draw",
            "data": { "target": "all_other_players", "count": 3 },
            "message": "All other players draw 3 cards!"
          },
          {
            "criteria": { "rank": "plus" },
            "type": "custom_effect",
            "data": { "state_changes": { "must_play_again": true } },
            "message": "Player must play again!"
          }
        ]
      },
      
      "custom_actions": {
        "taki_sequence": {
          "description": "Play multiple cards of the same color after playing a TAKI card",
          "requirements": [
            { "type": "game_state", "property": "open_taki", "value": true }
          ],
          "state_changes": { "taki_mode": true }
        },
        "change_color": {
          "description": "Change the color after playing a wild card",
          "requirements": [
            { "type": "has_card", "criteria": { "type": "wild" } }
          ]
        }
      },
      
      "scoring": {
        "type": "elimination"
      }
    }
  }
}
```

This creates a fully functional TAKI game where:
- Players can match cards by color or rank
- Wild cards can always be played
- Special effects trigger automatically (skip, force draw, etc.)
- Custom actions allow TAKI sequences and color changes
- The deck is exactly defined with the right card counts