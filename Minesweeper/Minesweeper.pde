import java.util.*;
import java.awt.Point;  // Import the Point class

int SIZE = 32, MARGIN = 5, X_MAX = 30, Y_MAX = 20, bombChance = 5;
String[] BUTTON_TEXT = { "Easy", "Moderate", "Hard" };
int BUTTON_WIDTH = 150, BUTTON_HEIGHT = 60, BUTTON_SPACING = 20;
int BACKGROUND_R = 90, BACKGROUND_G = 200, BACKGROUND_B = 50;
boolean gameOn, aiHint, calculating;  // Booleans to restrict actions during and after the game
Square[][] squares;  // Array of squares to make up the minefield
Queue<Point> toDraw = new ArrayDeque<Point>();
Map<Point, Float> hintedSquares = new HashMap<Point, Float>();

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
void newGame() {
  gameOn = true;
  aiHint = false;
  calculating = false;
  // Initialise squares
  squares = new Square[X_MAX][Y_MAX];
  for (int x = 0; x < X_MAX; x++) {
    for (int y = 0; y < Y_MAX; y++) {
      // Create the Square objects
      squares[x][y] = new Square(x, y, random(bombChance) < 1);
    }
  }
  for (int x = 0; x < X_MAX; x++) {
    for (int y = 0; y < Y_MAX; y++) {
      // Draw target square
      Square target = squares[x][y];
      target.drawThis(SIZE, MARGIN);

      // Tally up the number of adjacent Squares that are bombs
      boolean[] exists = adjacentSquaresBool(x, y);
      Point[] points = adjacentSquaresPoint(x, y);
      int adjMines = 0;
      for (int i = 0; i < exists.length; i++) {
        adjMines += (((exists[i])&&(squares[(int)points[i].getX()][(int)points[i].getY()].isMine())) ? 1 : 0);
      }
      target.setAdjacentMines(adjMines);
    }
  }
  drawButtons();
}

/** Return a set of booleans to whether the adjacent squares are within the array */
boolean[] adjacentSquaresBool(int x, int y) {
  boolean up = (y > 0), down = (y < Y_MAX-1), left = (x > 0), right = (x < X_MAX-1);
  boolean[] output = {up, (up&&right), right, (down&&right), down, (down&&left), left, (up&&left)};
  return output;
}

/** Return a set of points to represent the adjacent squares */
Point[] adjacentSquaresPoint(int x, int y) {
  Point[] output = {new Point(x, y-1), new Point(x+1, y-1), new Point(x+1, y), new Point(x+1, y+1),
    new Point(x, y+1), new Point(x-1, y+1), new Point(x-1, y), new Point(x-1, y-1)};
  return output;
}

/** Redraw the buttons at the bottom of the window */
void drawButtons() {
  float y = height-BUTTON_HEIGHT-BUTTON_SPACING*.5;
  // Draw the three restart buttons
  for (int i = 0; i < BUTTON_TEXT.length; i++) {
    // If it corresponds to the current difficulty, have different colouring
    if (bombChance == 6-i) {
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
  if (aiHint) {
    printOut = "AI Solver";
    stroke(153, 36, 49);
    fill(243, 49, 64);
  } else {
    stroke(104, 26, 104);
    fill(159, 43, 104);
  }
  rect(width-BUTTON_WIDTH-BUTTON_SPACING, y, BUTTON_WIDTH, BUTTON_HEIGHT);
  fill(25, 9, 25);
  text(printOut, width-BUTTON_WIDTH*0.5-BUTTON_SPACING, y+38);
}

/** The draw step updates the graphics when a change to the graphics is made */
void draw() {
  if (toDraw.size() == X_MAX*Y_MAX) {
    // If the board is being redrawn, generate a new board.
    newGame();
    // Remove any text in the bottom of the window
    fill(BACKGROUND_R, BACKGROUND_G, BACKGROUND_B);
    stroke(BACKGROUND_R, BACKGROUND_G, BACKGROUND_B);
    rect(3.5*BUTTON_SPACING+3*BUTTON_WIDTH, height-BUTTON_HEIGHT-BUTTON_SPACING*.5-1, .5*width-BUTTON_SPACING*4-BUTTON_WIDTH, BUTTON_HEIGHT+2);
  }

  // Removes hints from squares if they aren't going to be drawn, or they have been revealed or marked
  for (Point p : new HashSet<Point>(hintedSquares.keySet())) {
    Square target = squares[(int)p.getX()][(int)p.getY()];
    if (!toDraw.contains(p)||target.isRevealed()||target.isMarked()) {
      hintedSquares.remove(p);
      toDraw.add(p);
      aiHint = false;
    }
  }

  // Redraws all the squares that need to be drawn.
  while (!toDraw.isEmpty()) {
    Point p = toDraw.poll();
    Square target = squares[(int)p.getX()][(int)p.getY()];
    if (target.isRevealed()) {
      // If a mine is opened, then the game is over.
      if (target.isMine()) {
        gameOn = false;
        fill(250, 5, 5);
        text("GAME OVER!", BUTTON_SPACING+BUTTON_WIDTH + width*.5, height-BUTTON_HEIGHT*0.5);
      } else {
        // Check for a game-winning gamestate
        boolean allSpacesOpen = true;
        for (int x = 0; x < X_MAX; x++) {
          for (int y = 0; y < Y_MAX; y++) {
            allSpacesOpen = allSpacesOpen&&(squares[x][y].isRevealed()||squares[x][y].isMine());
          }
        }
        if (allSpacesOpen) {  // Game has been won!
          gameOn = false;
          fill(250, 5, 5);
          text("YOU WIN!", BUTTON_SPACING+BUTTON_WIDTH + width*.5, height-BUTTON_HEIGHT*0.5);
        } else if (target.getAdjacentMines() == 0) {
          // If a space is safe and all adjacents are also safe, open the adjacent spaces
          int x = target.getX(), y = target.getY();
          boolean[] exists = adjacentSquaresBool(x, y);
          Point[] points = adjacentSquaresPoint(x, y);
          for (int i = 0; i < exists.length; i++) {
            if (exists[i]) {
              Square adjacent = squares[(int)points[i].getX()][(int)points[i].getY()];
              if ((!adjacent.isMarked())&&(!adjacent.isRevealed())) {
                toDraw.add(points[i]);
                adjacent.reveal();
              }
            }
          }
        }
      }
    }
    target.drawThis(SIZE, MARGIN);
    if (hintedSquares.keySet().contains(p)) {
      double prob = hintedSquares.get(p);
      int red = (int)Math.max(5, Math.min((1-prob)*490, 245)+5);
      int green = (int)(Math.max(5, Math.min(prob*490, 245))-(245-red)*0.3)+5;
      stroke(red, green, 5);
      fill(red, green, 5);
      ellipse((target.getX()+0.5)*SIZE, (target.getY()+0.5)*SIZE, 0.5*SIZE, 0.5*SIZE);
    }
  }
  drawButtons();
}

/** The mouse event that figures out where the mouse clicked, and what to do according to the position*/
void mouseReleased() {
  if (calculating) {
    return;
  }  // No event if AI hints are being calculated

  //Get target square (if within the minefield)
  if ((mouseY < Y_MAX*SIZE)&&(gameOn)) {
    int x = (int)(mouseX - (mouseX % SIZE))/SIZE, y = (int)(mouseY - (mouseY % SIZE))/SIZE;
    Square target = squares[x][y];

    // Alter square
    if ((mouseButton == LEFT)&&(!target.isMarked())) {
      target.reveal();
    } else if (mouseButton == RIGHT) {
      target.changeMarked();
    }
    toDraw.add(new Point(x, y));
    redraw();
  } else if ((mouseY < height-BUTTON_SPACING*.5)&&(mouseY > height-BUTTON_HEIGHT-BUTTON_SPACING*.5)) {
    // If a button is being clicked
    for (int i = 0; i < BUTTON_TEXT.length; i++) {
      if ((mouseX > BUTTON_WIDTH*i+BUTTON_SPACING*(i+.5))&&(mouseX < BUTTON_WIDTH*(i+1)+BUTTON_SPACING*(i+.5))) {
        bombChance = 6-i;
        for (int x = 0; x < X_MAX; x++) {
          for (int y = 0; y < Y_MAX; y++) {
            toDraw.add(new Point(x, y));  // Redraw every square
          }
        }
        redraw();
      }
    }

    /** ADD AI BUTTON AND FUNCTIONALITY */
    if ((mouseX > width-BUTTON_WIDTH-BUTTON_SPACING)&&(mouseX < width-BUTTON_SPACING)&&gameOn) {
      if (aiHint) {
        uncoverHints();  // Removes hints, opens safe spaces and marks bombs
      } else {
        generateHints();  // Give hints to mine positioning
      }
      redraw();
    }
  }
}

/** A method to make an identical list to the input, but is separate
 *  in memory so not unwanted changes are made to the original. */
int[][] copy(int[][] a) {
  int[][] b = new int[a.length][a[0].length];
  for (int row = 0; row < a.length; row++) {
    for (int col = 0; col < a[0].length; col++) {
      b[row][col] = a[row][col];
    }
  }
  return b;
}

/** A program to help the player find bombs by using an algorithm to label some tiles */
void generateHints() {
  // Pause the game while generating hints
  gameOn = false;
  calculating = true;

  int[][] isSafe = new int[X_MAX][Y_MAX];
  for (int x = 0; x < X_MAX; x++) {
    for (int y = 0; y < Y_MAX; y++) {
      if (squares[x][y].isRevealed()) {
        isSafe[x][y] = 1; // Uncovered spaces are clearly safe
      } else {
        isSafe[x][y] = 0; // Unsure of covered spaces
      }
    }
  }

  // Does a simple check to find safe and unsafe squares
  isSafe = isSafeLoop(isSafe);

  // Hidden Squares
  List<Point> hSUnknown = new ArrayList<Point>();
  List<Point> hSquares = new ArrayList<Point>();

  // Get a set of all of the hidden spaces that have an adjacent, open space
  for (int x = 0; x < X_MAX; x++) {
    for (int y = 0; y < Y_MAX; y++) {
      if (!squares[x][y].isRevealed()) { // If hidden
        // Booleans for not going over the edges of the map
        boolean[] exists = adjacentSquaresBool(x, y);  // Booleans for not going over the edges of the map
        Point[] points = adjacentSquaresPoint(x, y);  // An array of points that surround the target

        boolean adjacentOpen = false;
        for (int i = 0; i < exists.length; i++) {
          if (exists[i]) {  // If there exists a space in given direction
            adjacentOpen = adjacentOpen||squares[(int)points[i].getX()][(int)points[i].getY()].isRevealed();
            // If an adjacent space is NOT hidden, then adjacentOpen = true
          }
        }
        if (adjacentOpen) {
          hSquares.add(new Point(x, y));  // Hidden squares
          if (isSafe[x][y] == 0) {
            hSUnknown.add(new Point(x, y));  // Hidden squares that have not been found
          }
        }
      }
    }
  }
  
  // Re-orders hSUnknown to help reduce the runtime of the recursive method
  if (!hSUnknown.isEmpty()) {
    float maxDistanceSum = 0;
    Point furthestPoint = hSUnknown.get(0);
    for (Point p1 : hSUnknown) {
      float distanceSum = 0;
      for (Point p2 : hSUnknown) {  // Add up the euclidean distances to all other points
        distanceSum += sqrt(pow((float)(p1.getX()-p2.getX()), 2.0) + pow((float)(p1.getY()-p2.getY()), 2.0));
      }
      if (maxDistanceSum < distanceSum) {
        maxDistanceSum = distanceSum;
        furthestPoint = p1;
      }
    }
    Set<Point> hSUnknownSet = new HashSet<Point>(hSUnknown);
    hSUnknown.clear();
    hSUnknownSet.remove(furthestPoint);
    hSUnknown.add(furthestPoint);
    while (!hSUnknownSet.isEmpty()) {  // Greedy algorithm to find shortest path to the next point
      float shortestDistance = maxDistanceSum;
      Point closestPoint = furthestPoint, previous = hSUnknown.get(hSUnknown.size()-1);
      for (Point p : hSUnknownSet) {
        float distance = sqrt(pow((float)(p.getX()-previous.getX()), 2.0) + pow((float)(p.getY()-previous.getY()), 2.0));
        if (shortestDistance > distance) {
          shortestDistance = distance;
          closestPoint = p;
        }
      }
      // Add the next point that is closest to the previous one to the list
      hSUnknownSet.remove(closestPoint);
      hSUnknown.add(closestPoint);
    }
  }

  // Use a recursive method to simulate the possible hidden values
  isSafe = isSafeRecursion(copy(isSafe), hSUnknown);

  int tallyMax = 1;
  for (int x = 0; x < X_MAX; x++) {
    for (int y = 0; y < Y_MAX; y++) {
      tallyMax = max(tallyMax, abs(isSafe[x][y]));
    }
  }
  float divisor = 1.0/tallyMax;
  float[][] isSafeTally = new float[X_MAX][Y_MAX];
  for (int x = 0; x < X_MAX; x++) {
    for (int y = 0; y < Y_MAX; y++) {
      isSafeTally[x][y] = isSafe[x][y]*divisor;
    }
  }

  // Unpause the hints
  gameOn = true;
  calculating = false;

  // Display unexposed safe and unsafe spaces
  displaySafes(hSquares, isSafeTally);
}

/** A method to find spaces that have to be safe */
public int[][] findSafes(int[][] isSafe) {
  int[][] surroundingBombs = new int[X_MAX][Y_MAX];
  for (int x = 0; x < X_MAX; x++) {
    for (int y = 0; y < Y_MAX; y++) {
      int visibleState = (squares[x][y].isRevealed()) ? squares[x][y].getAdjacentMines() : -1;
      if (visibleState != -1) {  // If not hidden

        boolean[] exists = adjacentSquaresBool(x, y);  // Booleans for not going over the edges of the map
        Point[] points = adjacentSquaresPoint(x, y);  // An array of points that surround the target

        surroundingBombs[x][y] = 0;  // Tally of bombs surrounding square[x][y]
        for (int i = 0; i < exists.length; i++) {
          if (exists[i]) {  // If there exists a space in given direction
            if (isSafe[(int)points[i].getX()][(int)points[i].getY()] == -1) {  // If the space is a bomb
              surroundingBombs[x][y]++;
            }
          }
        }

        // If there is the same number of hidden spaces as bombs around the space, save them as bombs
        if (visibleState == surroundingBombs[x][y]) {
          for (int i = 0; i < exists.length; i++) {
            if (exists[i]) {  // If there exists a space in given direction
              if (isSafe[(int)points[i].getX()][(int)points[i].getY()] == 0) {  // If the space was previously unknown
                // The corresponding space is safe
                isSafe[(int)points[i].getX()][(int)points[i].getY()] = 1;

                // This lets the method know that a new known space has been found
                aiHint = false;
              }
            }
          }
        }
      }
    }
  }
  return isSafe;
}

/** A method to find spaces that have to be bombs */
public int[][] findUnsafes(int[][] isSafe) {
  int[][] unknownSquares = new int[X_MAX][Y_MAX];
  for (int x = 0; x < X_MAX; x++) {
    for (int y = 0; y < Y_MAX; y++) {
      int visibleState = (squares[x][y].isRevealed() ? squares[x][y].getAdjacentMines() : -1);
      if (squares[x][y].isRevealed()) {
        boolean[] exists = adjacentSquaresBool(x, y);  // Booleans for not going over the edges of the map
        Point[] points = adjacentSquaresPoint(x, y);  // An array of points that surround the target

        unknownSquares[x][y] = 0;
        for (int i = 0; i < exists.length; i++) {
          if (exists[i]) {  // If there exists a space in given direction
            int adjX = (int)points[i].getX(), adjY = (int)points[i].getY();
            boolean hidden = !squares[adjX][adjY].isRevealed();
            boolean unknown = (isSafe[adjX][adjY] == 0);
            boolean bomb = (isSafe[adjX][adjY] == -1);
            if (hidden&&(unknown||bomb)) {
              unknownSquares[x][y]++;
            }
          }
        }

        // If there is the same number of non-safe hidden spaces as bombs around the space, save them as bombs
        if (visibleState == unknownSquares[x][y]) {
          for (int i = 0; i < exists.length; i++) {
            if (exists[i]) {  // If there exists a space in given direction
              int adjX = (int)points[i].getX(), adjY = (int)points[i].getY();
              boolean hidden = !squares[adjX][adjY].isRevealed();
              boolean unknown = (isSafe[adjX][adjY] == 0);
              if (hidden&&unknown) {
                // The corresponding space is not safe
                isSafe[adjX][adjY] = -1;

                // This lets the method know that a new known space has been found
                aiHint = false;
              }
            }
          }
        }
      }
    }
  }
  return isSafe;
}

/** A method to give labels to the spaces that have been found to be bombs or safe spaces */
public void displaySafes(List<Point> dSquares, float[][] isSafe) {
  for (Point p : dSquares) {
    int x = (int)p.getX(), y = (int)p.getY();
    if (!squares[x][y].isMarked()) {
      float prob = 0.5*(isSafe[x][y]+1);

      // Record hinted squares, their position, and what they are hinted as
      hintedSquares.put(p, prob);
      toDraw.add(new Point(x, y));
    }
  }
}

/** A recursive method to simulate all possible outcomes, and returns the sum of the outcomes */
int[][] isSafeRecursion(int[][] simulation, List<Point> hSUnknown) {
  if (hSUnknown.isEmpty()) {  // If the simulation has made it this far, then it is possible
    return simulation;
  } else {
    int[][] blank = new int[X_MAX][Y_MAX];
    for (int x = 0; x < X_MAX; x++) {
      for (int y = 0; y < Y_MAX; y++) {
        blank[x][y] = 0;
      }
    }

    // Get point to simulate
    Point p = hSUnknown.remove(hSUnknown.size()-1);

    // Simulate whether the point is a bomb or not
    int[][][] simulations = new int[2][X_MAX][Y_MAX];
    for (int n = 0; n < 2; n++) {
      int x = (int)p.getX(), y = (int)p.getY();
      // Creates a new branch to simulate
      simulations[n] = copy(simulation);
      simulations[n][x][y] = n*2-1;

      // Check to see if the branch may yield possible outcomes
      boolean[] exists = adjacentSquaresBool(x, y);
      Point[] points = adjacentSquaresPoint(x, y);
      for (int i = 0; i < exists.length; i++) {  // For each square around the given point:
        x = (int)points[i].getX();
        y = (int)points[i].getY();
        // If revealed, see if the surrounding squares add up
        if (exists[i]&&(squares[x][y].isRevealed())) {
          Square target = squares[x][y];
          boolean surroundingsAreFound = true;
          int surroundingSum = 0;
          boolean[] existsAdj = adjacentSquaresBool(x, y);
          Point[] pointsAdj = adjacentSquaresPoint(x, y);
          // See if the outcome is valid
          for (int j = 0; j < exists.length; j++) {
            x = (int)pointsAdj[j].getX();
            y = (int)pointsAdj[j].getY();
            boolean targetFound = (!existsAdj[j])||(simulations[n][x][y] != 0);
            surroundingsAreFound = surroundingsAreFound&&targetFound;
            if ((existsAdj[j])&&(simulations[n][x][y] == -1)) {
              surroundingSum++;
            }
          }

          // If this simulation is invalid, zero it out
          if ((surroundingSum > target.getAdjacentMines())||(surroundingsAreFound&&(surroundingSum < target.getAdjacentMines()))) {
            simulations[n] = blank;
            break;
          }
        }
      }

      // If the branch may yield possible outcomes, see where they lead
      if (simulations[n] != blank) {
        simulations[n] = isSafeRecursion(simulations[n], hSUnknown);
      }
    }
    
    // Put point back into list to be reused later
    hSUnknown.add(p);
    
    // Merge the results of the two simulations
    for (int x = 0; x < X_MAX; x++) {
      for (int y = 0; y < Y_MAX; y++) {
        simulations[0][x][y] += simulations[1][x][y];
      }
    }
    return simulations[0];
  }
}

/** A method to find spaces that iterates between finding safe and unsafe spaces */
int[][] isSafeLoop(int[][] isSafe) {
  aiHint = false;
  while (!aiHint) {
    aiHint = true;

    // Finds the safe and unsafe spaces
    isSafe = findUnsafes(isSafe);
    isSafe = findSafes(isSafe);
    // If any safe or unsafe spaces are found, help = false

    // If no new safe or unsafe spaces have been found, end the loop
  }
  return isSafe;
}

/** Makes changes to the squares that are almost certainly a bomb or a safe square */
void uncoverHints() {
  for (Point p : hintedSquares.keySet()) {
    int x = (int)p.getX(), y = (int)p.getY();
    if (hintedSquares.get(p) < 0.01) {
      squares[x][y].mark();  // If over 99% likely to be a bomb, mark this square
    } else if (hintedSquares.get(p) > 0.99) {
      squares[x][y].reveal();  // If over 99% likely to be safe, reveal this square
    }
  }
}
