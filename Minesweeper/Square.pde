public class Square {
  // instance variables - replace the example below with your own
  private int x, y, adjacentMines = 0;
  private boolean mine, revealed = false, marked = false;

  /**
   * Constructor for objects of class Square
   */
  public Square(int x_, int y_, boolean mine_) {
    // initialise instance variables
    this.x = x_;
    this.y = y_;
    this.mine = mine_;
  }

  /** Sets the number of adjacent bombs for the Square */
  void setAdjacentMines(int n) {
    this.adjacentMines = n;
  }

  /** Returns the number of adjacent bombs for the Square */
  int getAdjacentMines() {
    return this.adjacentMines;
  }

  /** Returns the X-position for the Square */
  int getX() {
    return this.x;
  }

  /** Returns the Y-position for the Square */
  int getY() {
    return this.y;
  }

  /** Returns whether the Square is a mine */
  boolean isMine() {
    return mine;
  }

  /** Returns whether the Square is revealed */
  boolean isRevealed() {
    return revealed;
  }

  /** Reveals the Square */
  void reveal() {
    revealed = true;
  }

  /** Returns whether the Square is marked */
  boolean isMarked() {
    return marked;
  }

  /** Changes the Square between being Marked and Unmarked*/
  void changeMarked() {
    marked = !marked;
  }

  /** Marks the Square */
  void mark() {
    marked = true;
  }

  /** Unmarks the Square */
  void unmark() {
    marked = false;
  }

  /** Draws the Square at its position*/
  void drawThis(int size, int border) {
    float printX = (this.getX()+0.5)*size, printY = (this.getY()+0.75)*size;
    if (this.isRevealed()) {
      stroke(50, 50, 150);
      fill(50, 50, 190);
      rect(this.getX()*size+border*0.5, this.getY()*size+border*0.5, size-border, size-border);
      int mines = (this.isMine() ? 9 : this.getAdjacentMines());  // Text colour is determined by the number of mines
      fill(min(50*mines, 250), min(50*(9-mines), 250), 5);
      if (this.isMine()){ text("*", printX, printY); }
      else if (this.getAdjacentMines() != 0){ text(this.getAdjacentMines(), printX, printY); }
    } else {
      stroke(70, 180, 30); 
      fill(110, 220, 70);
      rect(this.getX()*size+border*0.5, this.getY()*size+border*0.5, size-border, size-border);
      if (this.isMarked()) {
        fill(159, 43, 104);
        text("!", printX, printY);
      }
    }
  }
}
