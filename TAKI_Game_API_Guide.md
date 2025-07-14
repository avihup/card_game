# Card Games API - Comprehensive Guide

## 🎮 Overview

This comprehensive guide covers the Card Games API system that allows you to create, configure, and play ANY custom card game. The included Postman collection demonstrates the complete workflow using TAKI as an example, but the same principles apply to any card game you want to implement.

## 🏗️ How the Card Games App Works

### System Architecture

The Card Games API is built on a flexible, rule-based architecture that separates game logic from game data, allowing you to create virtually any card game by defining rules rather than writing code.

#### Core Components

**1. Game Rules Engine**
- **Game Rules**: Define the structure, deck, and rules for any card game
- **Deck Generator**: Dynamically creates card decks based on configuration
- **Rules Validator**: Ensures game rules are valid and complete
- **Play Rules Engine**: Validates moves and enforces game mechanics

**2. Game Session Management**
- **Game Sessions**: Individual game instances with their own state
- **Player Management**: Handles multiple players joining/leaving games
- **Turn Management**: Controls player turns and game flow
- **State Persistence**: Maintains complete game state throughout play

**3. Card System**
- **Dynamic Card Generation**: Creates cards with any properties you define
- **Card Validation**: Ensures played cards follow the game's rules
- **Hand Management**: Tracks each player's cards privately
- **Deck Management**: Handles shuffling, dealing, and drawing

### Game Creation Process

#### Step 1: Define Game Rules
Create a `GameRule` that defines your card game:

```json
{
  "name": "Your Custom Game",
  "description": "Description of your game",
  "deck_size": 52,
  "min_players": 2,
  "max_players": 6,
  "rules_data": {
    "initial_hand_size": 7,
    "win_condition": "first_to_empty_hand",
    "turn_actions": ["play_card", "draw_card", "pass"],
    "deck_configuration": {
      "cards": [
        {
          "suit": "hearts",
          "rank": "A", 
          "value": 1,
          "color": "red",
          "type": "number",
          "count": 1
        }
        // ... define all your cards
      ]
    },
    "card_play_rules": {
      "play_rules": [
        {
          "type": "match_any_properties",
          "properties": ["suit", "rank"]
        }
      ]
    }
  }
}
```

**Key Rule Components:**
- **Deck Configuration**: Define every card type with properties (suit, rank, value, color, type, etc.)
- **Play Rules**: Define when cards can be played (match suit, match rank, always playable, etc.)
- **Turn Actions**: What actions players can take (play_card, draw_card, pass, custom actions)
- **Win Conditions**: How the game ends (empty hand, highest score, last player standing)
- **Special Effects**: Cards that trigger special behaviors (skip turns, reverse direction, force draws)

#### Step 2: Flexible Card Properties
Cards can have ANY properties you define:
- **Standard**: `suit`, `rank`, `value`, `color`, `type`
- **Custom**: `power`, `element`, `cost`, `rarity`, `effect` - anything your game needs
- **Counts**: How many of each card type to include in the deck

#### Step 3: Rule Validation
The system automatically validates your rules:
- Ensures deck size matches total card counts
- Validates required fields are present
- Checks rule logic consistency
- Prevents invalid game configurations

### Game Session Lifecycle

#### Phase 1: Session Creation
```
POST /api/v1/game_sessions
```
- Creates a new game instance using your defined rules
- Sets initial status to "waiting"
- Creator automatically becomes first player
- Generates unique session ID

#### Phase 2: Player Joining
```
POST /api/v1/game_sessions/{id}/join
```
- Additional players join the session
- Each player gets a unique position/turn order
- Validates player count within game rule limits
- Session remains in "waiting" status until ready

#### Phase 3: Game Start
```
POST /api/v1/game_sessions/{id}/start
```
- Generates the deck using your deck configuration
- Shuffles cards (configurable)
- Deals initial hands to all players (size defined in rules)
- Sets game status to "active"
- Initializes turn management (current player, turn count)
- Creates initial game state

#### Phase 4: Active Gameplay
Players take turns performing actions defined in your rules:

**Available Actions** (configurable per game):
- `play_card`: Play a card from hand (validated against play rules)
- `draw_card`: Draw from deck (if allowed by rules)
- `pass`: Skip turn (if allowed)
- `discard`: Discard cards (if allowed)
- **Custom Actions**: Define game-specific actions

#### Phase 5: Game End
- Win condition checked after each turn
- Game ends when condition met (empty hand, score threshold, etc.)
- Final scores calculated using scoring rules
- Session marked as "finished"

### Turn-Based Gameplay Mechanics

#### Turn Flow
1. **Validation**: Check if it's player's turn and game is active
2. **Action Processing**: Validate and execute the requested action
3. **Rule Enforcement**: Apply play rules, special effects, and game logic
4. **State Update**: Update game state, player hands, deck, discard pile
5. **Win Check**: Evaluate win conditions
6. **Next Player**: Advance to next player's turn
7. **Response**: Return updated game state

#### Card Play Validation
The engine validates card plays using flexible rules:

**Match Rules**:
```json
{
  "type": "match_any_properties",
  "properties": ["suit", "rank"]  // Card must match suit OR rank
}
```

**Always Playable**:
```json
{
  "type": "always_playable",
  "criteria": {"type": "wild"}  // Wild cards always playable
}
```

**Conditional Rules**:
```json
{
  "type": "conditional",
  "condition": {
    "type": "state_property",
    "property": "special_mode",
    "value": true
  }
}
```

#### Special Effects System
Define cards that trigger special behaviors:

```json
{
  "criteria": {"rank": "skip"},
  "type": "skip_player",
  "message": "Next player skipped"
}
```

**Built-in Effects**:
- `skip_player`: Skip next player's turn
- `reverse_direction`: Reverse play order
- `force_draw`: Make players draw cards
- `custom_effect`: Define your own behaviors

### Player Management

#### Authentication
Simple header-based authentication:
```
X-User-Id: unique_player_id
X-Username: player_display_name
```

#### Privacy & Security
- Players see their own complete hand
- Other players only see hand sizes
- Deck contents hidden during play
- Game state filtered by requesting player

#### Multiple Player Support
- 2-10 players per game (configurable)
- Turn order management
- Player positions and roles
- Individual scoring and statistics

### Game State Management

#### Complete State Tracking
The system maintains comprehensive game state:

```json
{
  "game_session": {
    "id": "session_id",
    "status": "active",
    "current_player_index": 0,
    "turn_count": 15,
    "players": [...],
    "game_state": {
      "deck_remaining": 23,
      "discard_pile": [...],
      "last_action": "Player 1 played Red 7",
      "special_conditions": {},
      "direction": "clockwise"
    }
  }
}
```

#### Real-time Updates
- Game state updated after every action
- Turn advancement automatic
- Win condition checking
- Score calculation
- Action history tracking

### Customization Examples

#### Create a Standard 52-Card Game
```json
{
  "deck_configuration": {
    "cards": [
      {"suit": "hearts", "rank": "A", "value": 1, "count": 1},
      {"suit": "hearts", "rank": "2", "value": 2, "count": 1},
      // ... all 52 cards
    ]
  },
  "card_play_rules": {
    "play_rules": [
      {"type": "match_any_properties", "properties": ["suit", "rank"]}
    ]
  }
}
```

#### Create a Custom Fantasy Game
```json
{
  "deck_configuration": {
    "cards": [
      {
        "element": "fire",
        "power": 10,
        "rarity": "legendary",
        "effect": "burn",
        "cost": 5,
        "count": 2
      }
    ]
  },
  "card_play_rules": {
    "play_rules": [
      {"type": "match_any_properties", "properties": ["element", "rarity"]}
    ]
  }
}
```

#### Create a Numbers-Only Game
```json
{
  "deck_configuration": {
    "cards": [
      {"number": 1, "color": "red", "count": 4},
      {"number": 2, "color": "blue", "count": 4}
    ]
  },
  "card_play_rules": {
    "play_rules": [
      {"type": "match_any_properties", "properties": ["number", "color"]}
    ]
  }
}
```

This flexible architecture means you can create virtually any card game - from traditional games like Poker, Bridge, or Hearts, to completely custom games with unique mechanics and card types.

## 📋 Prerequisites

1. **Rails API Server**: Make sure your Rails server is running on `http://localhost:3000`
2. **Postman**: Import the `TAKI_Game_Postman_Collection.json` file into Postman
3. **Database**: Ensure MongoDB is running and accessible

## 🚀 Quick Start

### 1. Import the Collection
- Open Postman
- Click "Import" and select the `TAKI_Game_Postman_Collection.json` file
- The collection demonstrates the complete workflow using TAKI as an example
- All endpoints and variables will be imported automatically

### 2. Configure Environment (Optional)
The collection uses collection variables that auto-configure:
- `base_url`: Defaults to `http://localhost:3000`
- `user1_id` and `user2_id`: Auto-generated unique player IDs
- `user1_name` and `user2_name`: Default player names

### 3. Run the Collection
Execute the requests in order to see a complete game creation and play workflow:
1. **Learn**: Study the TAKI example to understand the system
2. **Modify**: Adapt the requests to create your own custom games
3. **Test**: Use Postman Collection Runner for automated testing

## 📁 Collection Structure

The collection demonstrates a complete game workflow using TAKI as an example. These same endpoints work for ANY card game you create:

### 🏥 Health Check
**Endpoint**: `GET /api/v1/health`
- Verifies the API is running and database is connected
- No authentication required
- Should return status 200 with healthy response

### 🎯 Create Game Rule
**Endpoint**: `POST /api/v1/game_rules`
- Creates a game rule definition for any card game
- Example: Creates TAKI game rule with complete deck configuration
- Requires user authentication (headers)
- **Customize**: Replace TAKI configuration with your own game rules

### 📋 List Game Rules
**Endpoint**: `GET /api/v1/game_rules?search={game_name}`
- Lists available game rules with optional filtering
- Example: Searches for TAKI rules and stores the rule ID
- Essential for finding game rules to create sessions
- **Customize**: Search for your custom game rules

### 🎮 Create Game Session
**Endpoint**: `POST /api/v1/game_sessions`
- Creates a new game session using any game rule
- Example: Creates a TAKI game session
- Requires a valid game rule ID (auto-populated from previous step)
- Creator automatically joins as first player
- Status starts as "waiting"

### 👥 Additional Players Join
**Endpoint**: `POST /api/v1/game_sessions/{id}/join`
- Additional players join the game session
- Example: Second player joins TAKI game
- Uses different user credentials
- Game becomes ready when minimum player count reached

### 🚀 Start Game
**Endpoint**: `POST /api/v1/game_sessions/{id}/start`
- Starts the game and deals cards to players
- Example: Each TAKI player receives 8 cards
- Initial hand size defined in game rules
- Game status changes to "active"
- Sets current player and turn order

### 🔍 Get Game State
**Endpoint**: `GET /api/v1/game_sessions/{id}`
- Retrieves current game state with player-specific filtering
- Players see their own cards, but only card counts for others
- Shows current player, turn count, and complete game status
- **Universal**: Works the same for any card game

### 🎲 Play Actions
**Endpoint**: `POST /api/v1/game_sessions/{id}/play_turn`
Multiple action types supported:

**Play Card**:
- Player attempts to play a card from their hand
- Validates card against game-specific play rules
- Updates game state and advances to next player
- May trigger special card effects

**Draw Card**:
- Player draws a card from the deck
- Alternative action when unable to play
- Advances turn to next player
- Shows remaining deck size

**Custom Actions**:
- Execute game-specific actions (like TAKI sequences)
- Defined in the game rule's custom actions
- **Customize**: Define your own special game actions

## 🎯 TAKI Game Rules

The API implements the following TAKI rules:

### Card Types
- **Number Cards**: 1-9 in four colors (red, yellow, green, blue)
- **Action Cards**: 
  - `stop`: Skip next player
  - `plus`: Draw extra card
  - `change_direction`: Reverse play direction
  - `taki`: Play multiple cards of same color
- **Special Cards**:
  - `super_taki`: Universal TAKI card
  - `king`: Change color
  - `plus_three`: All other players draw 3 cards
  - `break_plus_three`: Block +3 and redirect
  - `change_color`: Wild card

### Play Rules
- Match color or number with the last played card
- Special and wild cards can always be played
- TAKI cards allow playing multiple cards of the same color
- First to empty their hand wins

### Game Flow
1. Each player starts with 8 cards
2. Players take turns playing valid cards or drawing
3. Special cards trigger immediate effects
4. Game ends when a player has no cards left

## 🔧 Authentication

The API uses simple header-based authentication:
```
X-User-Id: player1_1234567890
X-Username: Player One
```

No complex JWT tokens required for testing.

## ⚡ CSRF Protection

**Fixed**: The API controllers now skip CSRF token verification (as they should for REST APIs) by adding `skip_before_action :verify_authenticity_token` to the base controller. This resolves the "Can't verify CSRF token authenticity" error.

**⚠️ Important**: Restart your Rails server after this fix for the changes to take effect.

## 🔧 Rails 7.1 Compatibility

**Fixed**: Rails 7.1 introduced stricter validation for callback actions. Updated the authentication callback configuration to prevent "missing callback actions" errors:
- Removed `:health` from base controller exceptions (action doesn't exist)
- Added specific authentication skip for HealthController's `show` action
- This resolves callback validation errors in Rails 7.1+

## 📊 Game Management

### Additional Endpoints

- **Pause Game**: `POST /api/v1/game_sessions/{id}/pause`
- **Resume Game**: `POST /api/v1/game_sessions/{id}/resume`  
- **Leave Game**: `DELETE /api/v1/game_sessions/{id}/leave`
- **Cancel Game**: `POST /api/v1/game_sessions/{id}/cancel`
- **List Sessions**: `GET /api/v1/game_sessions?status=active`

## 🧪 Testing Features

### Automated Tests
Each request includes Postman tests that verify:
- Correct HTTP status codes
- Response structure and content
- Data persistence across requests
- Game state consistency

### Variable Management
The collection automatically:
- Generates unique player IDs
- Stores game session IDs
- Tracks current card IDs for playing
- Maintains TAKI rule references

### Error Handling
Tests gracefully handle:
- Invalid card plays (422 errors)
- Authentication failures
- Game state violations
- Network connectivity issues

## 🎯 Usage Scenarios

### Scenario 1: Quick Game Test (Using TAKI Example)
1. Run "Health Check"
2. Run "Create Game Rule" (creates TAKI rule)
3. Run "List Game Rules" (optional verification)
4. Run "Create Game Session" (creates TAKI session)
5. Run "Additional Players Join"
6. Run "Start Game"
7. Run "Get Game State" to see dealt cards

### Scenario 2: Full Gameplay Experience
Execute all requests in sequence to simulate:
- Complete game setup for any card game
- Multiple turns with card plays and draws
- Game state inspection from different player perspectives
- Game management (pause/resume/cancel)
- Game completion with win condition checking

### Scenario 3: Custom Game Development
1. Study the TAKI example structure
2. Design your own game rules and deck
3. Replace the game rule creation request with your custom configuration
4. Test your custom game using the same session endpoints
5. Iterate and refine your game mechanics

### Scenario 4: API Testing & Validation
Use Collection Runner to:
- Test all endpoints automatically
- Verify API functionality with any game type
- Check data consistency across game sessions
- Validate error handling and edge cases

## 🔍 Troubleshooting

### Common Issues

1. **"Game rule not found"**: Run "Create TAKI Game Rule" first
2. **"Authentication required"**: Check X-User-Id header is set  
3. **"CSRF token authenticity error"**: Fixed by disabling CSRF for API endpoints
4. **"Missing callback actions" (Rails 7.1)**: Fixed by updating authentication callback configuration
5. **"It's not your turn"**: Verify current player with "Get Game State"
6. **"Card cannot be played"**: Check TAKI play rules or try drawing instead

### Debug Information
- Check Postman Console for detailed logs
- Test scripts output game state information
- Response bodies contain error details
- Variables tab shows current session data

## 📚 API Documentation

For complete API documentation, visit:
- Swagger UI: `http://localhost:3000/api-docs`
- Health endpoint: `http://localhost:3000/api/v1/health`

## 🎮 Next Steps

### Learn the System
1. Run the TAKI example to understand the complete workflow
2. Study how game rules, sessions, and turns work together
3. Examine the card generation and validation system
4. Test different player scenarios and game states

### Create Your Own Games
1. Design your custom card game rules and mechanics
2. Define your deck with custom card properties
3. Set up play rules that match your game logic
4. Test your game with multiple players
5. Add special effects and custom actions

### Advanced Features
1. Experiment with different win conditions
2. Create games with 2-10 players
3. Test complex card interactions and special effects
4. Build games with custom scoring systems
5. Implement unique turn actions and game mechanics

### Game Types You Can Create
- **Traditional Games**: Poker, Bridge, Hearts, Spades, Go Fish
- **Modern Games**: UNO-style games, custom trading card games
- **Educational Games**: Math games, vocabulary games, trivia games
- **Fantasy Games**: Custom themes with unique card properties
- **Party Games**: Simple rules for group entertainment

## 🆘 Support

If you encounter issues:
1. Check the Rails server logs
2. Verify MongoDB connectivity
3. Ensure all required dependencies are installed
4. Check API documentation for endpoint details
5. Review the test scripts for expected behavior

## 📁 Additional Files

### `TAKI_Rule_Request_Body.json`
Standalone JSON request body for creating TAKI game rule directly via:
```
POST /api/v1/game_rules
Content-Type: application/json
X-User-Id: your_user_id
X-Username: your_username

{... content from TAKI_Rule_Request_Body.json ...}
```

This file contains the complete TAKI deck configuration with all 4 colors (red, yellow, green, blue) and can be used independently of the Postman collection.

Happy gaming! 🎲 