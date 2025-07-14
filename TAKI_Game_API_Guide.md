# TAKI Card Game API - Postman Collection Guide

## 🎮 Overview

This Postman collection provides a complete workflow for creating and playing TAKI card games using the Card Games API. TAKI is an Israeli card game similar to UNO, featuring colored number cards and special action cards.

## 📋 Prerequisites

1. **Rails API Server**: Make sure your Rails server is running on `http://localhost:3000`
2. **Postman**: Import the `TAKI_Game_Postman_Collection.json` file into Postman
3. **Database**: Ensure MongoDB is running and accessible

## 🚀 Quick Start

### 1. Import the Collection
- Open Postman
- Click "Import" and select the `TAKI_Game_Postman_Collection.json` file
- The collection will be imported with all endpoints and variables

### 2. Configure Environment (Optional)
The collection uses collection variables that auto-configure:
- `base_url`: Defaults to `http://localhost:3000`
- `user1_id` and `user2_id`: Auto-generated unique player IDs
- `user1_name` and `user2_name`: Default player names

### 3. Run the Collection
Execute the requests in order, or use the Postman Collection Runner for automated testing.

## 📁 Collection Structure

### 🏥 Health Check
**Endpoint**: `GET /api/v1/health`
- Verifies the API is running and database is connected
- No authentication required
- Should return status 200 with healthy response

### 🎯 Create TAKI Game Rule
**Endpoint**: `POST /api/v1/game_rules`
- Creates the TAKI game rule directly using the create endpoint
- Requires user authentication (headers)
- Contains complete TAKI deck configuration with all 4 colors

### 📋 List Game Rules
**Endpoint**: `GET /api/v1/game_rules?search=TAKI`
- Lists available game rules, filtering for TAKI
- Automatically stores the TAKI rule ID for later use
- Essential for finding the game rule to create sessions

### 🎮 Create TAKI Game Session
**Endpoint**: `POST /api/v1/game_sessions`
- Creates a new TAKI game session
- Requires the TAKI rule ID (auto-populated from previous step)
- Creator automatically joins as first player
- Status starts as "waiting"

### 👥 Player 2 Joins Game
**Endpoint**: `POST /api/v1/game_sessions/{id}/join`
- Second player joins the game
- Uses different user credentials (user2_id)
- Game becomes ready to start with minimum players

### 🚀 Start TAKI Game
**Endpoint**: `POST /api/v1/game_sessions/{id}/start`
- Starts the game and deals cards to players
- Each player receives 8 cards (TAKI initial hand size)
- Game status changes to "active"
- Sets current player index

### 🔍 Get Game State
**Endpoint**: `GET /api/v1/game_sessions/{id}`
- Retrieves current game state
- Different perspectives for different players
- Player sees their own cards, but only card count for others
- Shows current player, turn count, and game status

### 🎲 Play Card
**Endpoint**: `POST /api/v1/game_sessions/{id}/play_turn`
- Player attempts to play a card from their hand
- Validates card can be played according to TAKI rules
- Updates game state and advances to next player
- May trigger special card effects

### 📥 Draw Card
**Endpoint**: `POST /api/v1/game_sessions/{id}/play_turn`
- Player draws a card from the deck
- Alternative action when unable to play
- Advances turn to next player
- Shows remaining deck size

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

### Scenario 1: Quick Game Test
1. Run "Health Check"
2. Run "Create TAKI Game Rule" 
3. Run "List Game Rules" (optional verification)
4. Run "Create TAKI Game Session"
5. Run "Player 2 Joins Game"
6. Run "Start TAKI Game"
7. Run "Get Game State" to see dealt cards

### Scenario 2: Full Gameplay
Execute all requests in sequence to simulate:
- Complete game setup
- Multiple turns with card plays and draws
- Game state inspection from different players
- Game management (pause/resume)
- Game completion or cancellation

### Scenario 3: API Testing
Use Collection Runner to:
- Test all endpoints automatically
- Verify API functionality
- Check data consistency
- Validate error handling

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

After familiarizing yourself with the basic flow:
1. Try playing complete games
2. Test with more players (TAKI supports 2-10 players)
3. Experiment with different card combinations
4. Test special card effects
5. Explore custom game rules creation

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