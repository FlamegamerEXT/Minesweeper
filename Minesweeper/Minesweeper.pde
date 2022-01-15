import java.util.*;
import java.awt.Point;  // Import the Point class

int SIZE = 32, MARGIN = 5, X_MAX = 30, Y_MAX = 20, bombChance = 5;
String[] BUTTON_TEXT = { "Easy", "Moderate", "Hard" };
int BUTTON_WIDTH = 150, BUTTON_HEIGHT = 60, BUTTON_SPACING = 20;
int BACKGROUND_R = 90, BACKGROUND_G = 200, BACKGROUND_B = 50;
boolean gameOn, aiHint;
Square[][] squares;
Queue<Point> toDraw = new ArrayDeque<Point>();

/** Load the game to begin */
void setup() {
  // Initialise frame
  size(960, 720);
  noLoop();
  colorMode(RGB);
  background(BACKGROUND_R, BACKGROUND_G, BACKGROUND_B);
  textAlign(CENTER);
  textFont(createFont("Arial Bold", 24));
  strokeWeight(MARGIN);
  
  newGame();  // Generate gamestate
}

/** Create an array of new squares, and resets buttons and booleans */
void newGame(){
  // Initialise squares
  squares = new Square[X_MAX][Y_MAX];
  for (int x = 0; x < X_MAX; x++){
    for (int y = 0; y < Y_MAX; y++){
      // Create the Square objects
      squares[x][y] = new Square(x, y, random(bombChance) < 1);
    }
  }
  for (int x = 0; x < X_MAX; x++){
    for (int y = 0; y < Y_MAX; y++){
      // Draw target square
      Square target = squares[x][y];
      target.drawThis(SIZE, MARGIN);
      
      // Tally up the number of adjacent Squares that are bombs
      boolean[] exists = adjacentSquaresBool(x, y);
      Point[] points = adjacentSquaresPoint(x, y);
      int adjMines = 0;
      for (int i = 0; i < 8; i++){
        adjMines += (((exists[i])&&(squares[(int)points[i].getX()][(int)points[i].getY()].isMine())) ? 1 : 0);
      }
      target.setAdjacentMines(adjMines);
    }
  }
  drawButtons();
  gameOn = true;
  aiHint = false;
}

/** Return a set of booleans to whether the adjacent squares are within the array */
boolean[] adjacentSquaresBool(int x, int y){
  boolean up = (y > 0), down = (y < Y_MAX-1), left = (x > 0), right = (x < X_MAX-1);
  boolean[] output = {up, (up&&right), right, (down&&right), down, (down&&left), left, (up&&left)};
  return output;
}

/** Return a set of points to represent the adjacent squares */
Point[] adjacentSquaresPoint(int x, int y){
  Point[] output = {new Point(x, y-1), new Point(x+1, y-1), new Point(x+1, y), new Point(x+1, y+1),
                    new Point(x, y+1), new Point(x-1, y+1), new Point(x-1, y), new Point(x-1, y-1)};
  return output;
}

/** Redraw the buttons at the bottom of the window */
void drawButtons(){
  float y = height-BUTTON_HEIGHT-BUTTON_SPACING*.5;
  // Draw the three restart button
  for (int i = 0; i < BUTTON_TEXT.length; i++){
    // If it corresponds to the current difficulty, have different colouring
    if (bombChance == 6-i){
      stroke(169, 100, 49);
      fill(225, 144, 64);
    } else {
      stroke(169, 169, 49);
      fill(225, 225, 104);
    }
    rect(BUTTON_SPACING+i*(BUTTON_SPACING+BUTTON_WIDTH), y, BUTTON_WIDTH, BUTTON_HEIGHT);
    fill(25, 25, 9);
    text("New Game", BUTTON_WIDTH*.5+BUTTON_SPACING+i*(BUTTON_SPACING+BUTTON_WIDTH), y+25);
    text("("+BUTTON_TEXT[i]+")", BUTTON_WIDTH*.5+BUTTON_SPACING+i*(BUTTON_SPACING+BUTTON_WIDTH), y+50);
  }
  
  // Draw the AI button
  String printOut = "AI Helper";
  if (aiHint){
    printOut = "AI Solver";
    stroke(153, 36, 49);
    fill(243, 49, 64);
  } else {
    stroke(104, 26, 104);
    fill(159, 43, 104);
  }
  rect(width-BUTTON_WIDTH-BUTTON_SPACING, y, BUTTON_WIDTH, BUTTON_HEIGHT);
  fill(25, 9, 25);
  text(printOut,width-BUTTON_WIDTH*0.5-BUTTON_SPACING, y+38);
  
  // Remove any text in the bottom of the window
  fill(BACKGROUND_R, BACKGROUND_G, BACKGROUND_B);
  stroke(BACKGROUND_R, BACKGROUND_G, BACKGROUND_B);
  rect((width+BUTTON_WIDTH-BUTTON_SPACING)*.5, y, BUTTON_WIDTH*1.5, BUTTON_HEIGHT);
}

/** The draw step updates the graphics when  */
void draw(){
  if (toDraw.size() == X_MAX*Y_MAX){
    newGame();  // If the board is being redrawn, generate a new board.
  }
  while (!toDraw.isEmpty()){  // Redraws all the squares that need to be drawn.
    Point p = toDraw.poll();
    Square target = squares[(int)p.getX()][(int)p.getY()];
    if (target.isRevealed()) {
      // If a mine is opened, then the game is over.
      if (target.isMine()) {
        gameOn = false;
        fill(250, 5, 5);
        text("GAME OVER!", width*.5+BUTTON_WIDTH, height-BUTTON_HEIGHT*0.5);
      } else {
        // Check for a game-winning gamestate
        boolean allSpacesOpen = true;
        for (int x = 0; x < X_MAX; x++){
          for (int y = 0; y < Y_MAX; y++){
            allSpacesOpen = allSpacesOpen&&(squares[x][y].isRevealed()||squares[x][y].isMine());
          }
        }
        if (allSpacesOpen){  // Game has been won!
          gameOn = false;
          fill(250, 5, 5);
          text("YOU WIN!", width*.5+BUTTON_WIDTH, height-BUTTON_HEIGHT*0.5);
        } else if (target.getAdjacentMines() == 0){
          // If a space is safe and all adjacents are also safe, open the adjacent spaces
          int x = target.getX(), y = target.getY();
          boolean[] exists = adjacentSquaresBool(x, y);
          Point[] points = adjacentSquaresPoint(x, y);
          for (int i = 0; i < 8; i++){
            if (exists[i]){
              Square adjacent = squares[(int)points[i].getX()][(int)points[i].getY()];
              if ((!adjacent.isMarked())&&(!adjacent.isRevealed())){
                toDraw.add(points[i]);
                adjacent.reveal();
              }
            }
          }
        }
      }
    }
    target.drawThis(SIZE, MARGIN);
  }
}

void mouseReleased() {
  //Get target square
  int x = (int)(mouseX - (mouseX % SIZE))/SIZE, y = (int)(mouseY - (mouseY % SIZE))/SIZE;
  if ((y < Y_MAX*SIZE)&&(gameOn)) {
    Square target = squares[x][y];
    
    // Alter square
    if ((mouseButton == LEFT)&&(!target.isMarked())) {
      target.reveal();
    } else if (mouseButton == RIGHT) {
      target.changeMarked();
    }
    toDraw.add(new Point(x, y));
    redraw();
  } else if ((mouseY < height-BUTTON_SPACING*.5)&&(mouseY > height-BUTTON_HEIGHT-BUTTON_SPACING*.5)){
    // If a button is being clicked
    for (int i = 0; i < BUTTON_TEXT.length; i++){
      if ((mouseX > BUTTON_WIDTH*i+BUTTON_SPACING*(i+.5))&&(mouseX < BUTTON_WIDTH*(i+1)+BUTTON_SPACING*(i+.5))){
        gameOn = false;
        bombChance = 6-i;
        newGame();
        for (x = 0; x < X_MAX; x++){
          for (y = 0; y < Y_MAX; y++){
            toDraw.add(new Point(x, y));  // Redraw every square
          }
        }
        redraw();
      }
    }
    /** ADD AI BUTTON AND FUNCTIONALITY */
  }
  
}
