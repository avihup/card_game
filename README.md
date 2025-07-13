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
    "card_index": 0
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
      "card_index": 0
    }
  }'
```

## 🎲 Built-in Game Templates

The system comes with several pre-configured game templates:

1. **Classic UNO** - The classic UNO card game (2-10 players)
2. **Go Fish** - Classic Go Fish card game (2-6 players)
3. **Crazy Eights** - Classic Crazy Eights card game (2-7 players)
4. **Speed Cards** - Fast-paced card matching game (2-4 players)
5. **Memory Match** - Card memory and matching game (2-6 players)

## 🔧 Game Rule Structure

Game rules are defined using a flexible JSON structure:

```json
{
  "name": "Game Name",
  "description": "Game description",
  "min_players": 2,
  "max_players": 4,
  "deck_size": 52,
  "rules_data": {
    "initial_hand_size": 7,
    "win_condition": "first_to_empty_hand",
    "turn_actions": ["play_card", "draw_card", "pass"],
    "special_rules": {
      "crazy_eights": true,
      "match_suit_or_rank": true
    },
    "scoring": {
      "type": "elimination",
      "points": {}
    }
  }
}
```

### Win Conditions
- `first_to_empty_hand`: First player to empty their hand wins
- `highest_score`: Player with highest score wins
- `lowest_score`: Player with lowest score wins
- `last_player_standing`: Last active player wins

### Turn Actions
- `play_card`: Play a card from hand
- `draw_card`: Draw a card from deck
- `pass`: Pass the turn
- `discard`: Discard a card
- `skip_turn`: Skip the turn

## 🛠️ Development

### Running Tests
```bash
# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/models/game_rule_spec.rb
```

### Generate Swagger Documentation
```bash
# Generate swagger specs
bundle exec rails rswag:specs:swaggerize
```

### Database Operations
```bash
# Seed database with default games
rails db:seed

# Open MongoDB console
mongosh card_games_development
```

## 📊 API Response Format

All API responses follow a consistent format:

### Success Response
```json
{
  "success": true,
  "data": { ... },
  "message": "Optional success message"
}
```

### Error Response
```json
{
  "success": false,
  "errors": ["Error message 1", "Error message 2"],
  "message": "Optional error message"
}
```

### Pagination
```json
{
  "success": true,
  "data": {
    "game_rules": [ ... ],
    "pagination": {
      "current_page": 1,
      "per_page": 10,
      "total_pages": 5,
      "total_count": 50
    }
  }
}
```

## 🔍 Health Check

Check API health and database connectivity:
```bash
GET /api/v1/health
```

Response:
```json
{
  "success": true,
  "data": {
    "status": "healthy",
    "version": "1.0.0",
    "environment": "development",
    "timestamp": "2024-01-15T10:30:00Z",
    "database": {
      "status": "connected",
      "type": "MongoDB"
    },
    "services": {
      "game_rules": 5,
      "game_sessions": 2,
      "waiting_games": 1
    }
  }
}
```

## 🚀 Deployment

### Docker
```dockerfile
# Build and run with Docker
docker build -t card_games_api .
docker run -p 3000:3000 card_games_api
```

### Environment Variables
- `RAILS_ENV`: Set to `production` for production deployment
- `MONGODB_URL`: MongoDB connection string
- `SECRET_KEY_BASE`: Secret key for production

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

For support and questions:
- Check the [Swagger documentation](http://localhost:3000/api-docs)
- Review the API examples above
- Create an issue in the repository

---

## 📈 Future Enhancements

- [ ] JWT authentication implementation
- [ ] WebSocket integration for real-time updates
- [ ] Player statistics and leaderboards
- [ ] Tournament management
- [ ] Advanced game rule validation
- [ ] Game replay functionality
- [ ] Mobile app API endpoints
