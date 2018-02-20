/* @pjs preload="/data/data.csv"; */
int SIZEX;
int SIZEY;
PFont f, f2;
Table tab;

float oldWidth, oldHeight, fontSize = 12;
float DATA_X_START = 100;
float DATA_X_END = 700;
float DATA_Y_START = 75;
float DATA_Y_END = 500;
float MIN_HRANGE = 10;
float SELECT_WIDTH = 0.75f;
float AXIS_WIDTH = 10;
float TEXT_XOFFSET = 15;
float TEXT_YOFFSET = 20;
float BUTTON_YOFFSET = 25;
float BUTTON_WIDTH = 50;
float BUTTON_HEIGHT = 25;
float LINE_STROKE = 4;
float HIGHLIGHT_BUFFER = 1.0f;

float minScale = 0;
float maxScale = 0;
boolean scale = false;
boolean rs = false;

Axis nearestA;

float rsX, rsY, rsW, rsH;

Axis[] axis;

ArrayList<LineNode> allNodes = new ArrayList<LineNode>();
ArrayList<Drawable> components = new ArrayList<Drawable>();
ArrayList<Range> ranges = new ArrayList<Range>();

LineNode tooltipLock = null;


interface Drawable {
  void drawShape();
  void resizeSelf(float ow, float oh, float nw, float nh);
}

interface Range {
  void mouseMove(float x, float y);
  void mouseRelease(float x, float y);
  void mousePress(float x, float y);
}

void mousePressed() {
  minScale = mouseY;
  rs = true;
  rsX = mouseX;
  if(mouseY < axis[0].getY() + axis[0].getHeight()) {
    if(mouseY > axis[0].getY()) {
      rsY = mouseY;
    } else {
      rsY = axis[0].getY();
    }
  } else {
    rsY = axis[0].getY() + axis[0].getHeight();
  }
  
  rsW = 1;
  rsH = 1;
  for(int i = 0; i < components.size(); i++) {
    if(components.get(i) instanceof LineNode) {
      ((LineNode)components.get(i)).unhighlight();
    }
  }
  for(int i = 0; i < ranges.size(); i++) {
    ranges.get(i).mousePress(mouseX, mouseY);
  }
}

Axis findNearestAxis(float x) {
  Axis nearest = axis[0];
  for(int i = 0; i < axis.length; i++) {
    if(Math.abs(axis[i].getX() - x) < Math.abs(nearest.getX() - x)) {
      nearest = axis[i];
    }
  }
  return nearest;
}

void colorByAxis(Axis a) {
  a.colorChildren();
}

boolean mouseInLine(float x1, float y1, float x2, float y2, float px, float py) {

  float d1 = dist(px, py, x1, y1);
  float d2 = dist(px, py, x2, y2);

  float len = dist(x1, y1, x2, y2);

  return (d1 + d2 >= len - HIGHLIGHT_BUFFER && d1 + d2 <= len + HIGHLIGHT_BUFFER);
}

boolean mouseInLine2(float x1, float y1, float x2, float y2, float mx, float my)
{
    double normalLength = Math.sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1));
    return Math.abs((mx - x1) * (y2 - y1) - (my - y1) * (x2 - x1)) / normalLength < LINE_STROKE;
}


void mouseReleased() {
  for(int i = 0; i < axis.length; i++) {
    axis[i].unselectChildren();
  }
  maxScale = mouseY;
  rs = false;
  if(Math.abs(minScale - maxScale) > MIN_HRANGE) {
    ArrayList<LineNode> children = findNearestAxis(mouseX).getChildren();
    for(int i = 0; i < children.size(); i++) {
      if(minScale < maxScale) {
        if(children.get(i).getYDraw() > minScale && children.get(i).getYDraw() < maxScale) {
          children.get(i).highlight();
          children.get(i).select(1);
          children.get(i).select(-1);
        }
      } else {
        if(children.get(i).getYDraw() < minScale && children.get(i).getYDraw() > maxScale) {
          children.get(i).highlight();
          children.get(i).select(1);
          children.get(i).select(-1);
        }
      }
    }
  }
  for(int i = 0; i < ranges.size(); i++) {
    ranges.get(i).mouseRelease(mouseX, mouseY);
  }
  mouseMoved();
}

void mouseDragged() {
  rsW = mouseX - rsX;
  if(mouseY < axis[0].getY() + axis[0].getHeight()) {
    if(mouseY > axis[0].getY()) {
      rsH = mouseY - rsY;
    } else {
      rsH = axis[0].getY() - rsY;
    }
  } else {
    rsH = axis[0].getY() + axis[0].getHeight() - rsY;
  }
}

void mouseMoved() {
  for(int i = 0; i < ranges.size(); i++) {
    ranges.get(i).mouseMove(mouseX, mouseY);
  }
  for(int i = 0; i < allNodes.size(); i++) {
    LineNode node = allNodes.get(i);
    while(node.getNext() != null) {
      if(mouseInLine(node.getX(), node.getYDraw(), node.getNext().getX(), node.getNext().getYDraw(), mouseX, mouseY)) {
        node.highlight();
        node.lock(1);
        node.lock(-1);
      } else {
        node.unhighlight();
      }
      node = node.getNext();
    }
  }
  for(int i = 0; i < allNodes.size(); i++) {
    allNodes.get(i).unlock(1);
    allNodes.get(i).unlock(-1);
  }
}

void setup() {
  surface.setResizable(true);
  
  SIZEX = 800;
  SIZEY = 600;
  size(800, 600);
  oldWidth = width;
  oldHeight = height;
  f = createFont("Arial_Bold",12,true);
  f2 = createFont("Arial_Bold",20,true);
  textFont(f,fontSize);
  readInData();
}

void draw() {
  background(220, 220, 220);
  for(Drawable d : components) {
    d.drawShape();
  }
  if(width != oldWidth || height != oldHeight) {
    for(int i = 0; i < components.size(); i++) {
      components.get(i).resizeSelf(oldWidth, oldHeight, width, height);
    }
    BUTTON_YOFFSET *= height/oldHeight;
    BUTTON_WIDTH *= width/oldWidth;
    BUTTON_HEIGHT *= height/oldHeight;
    TEXT_XOFFSET *= width/oldWidth;
    TEXT_YOFFSET *= height/oldHeight;
  }
  if(rs) {
    nearestA = findNearestAxis(mouseX);
  }
  fill(0, 0, 0, 100);
  stroke(0, 0, 0);
  rect(nearestA.getX() - nearestA.getWidth()*SELECT_WIDTH, rsY, nearestA.getWidth() + 2*nearestA.getWidth()*SELECT_WIDTH, rsH);
  if(tooltipLock != null && (!tooltipLock.isHighlighted())) {
    tooltipLock = null;
  }
  oldWidth = width;
  oldHeight = height;
}



void readInData() {
  tab = loadTable("data.csv", "header");
  TableRow labs = loadTable("data.csv").getRow(0);
  float curX = 100;
  float xinterval = (DATA_X_END - DATA_X_START)/(Math.max(tab.getColumnCount() - 2, 0));
  axis = new Axis[labs.getColumnCount()-1];
  for(int i = 1; i < labs.getColumnCount(); i++) {
    axis[i-1] = new Axis(labs.getString(i), curX, DATA_Y_START);
    components.add(new Button(axis[i-1].getX() - BUTTON_WIDTH/2, 
                              axis[i-1].getY() + axis[i-1].getHeight() + BUTTON_YOFFSET, 
                              BUTTON_WIDTH, 
                              BUTTON_HEIGHT));
    ranges.add((Range)components.get(components.size()-1));
    ranges.add(axis[i-1]);
    components.add(axis[i-1]);
    curX += xinterval;
    println(axis[i-1].getLabel());
  }
  nearestA = axis[0];
  for(TableRow row : tab.rows()) {
    curX = 100;
    LineNode node = new LineNode(row.getString(0), curX, row.getFloat(1), null, null, axis[0]);
    components.add(node);
    allNodes.add(node);
    for(int i = 2; i < row.getColumnCount(); i++) {
      curX += xinterval;
      node.setNext(new LineNode(row.getString(0), curX, row.getFloat(i), node, null, axis[i-1]));
      node = node.getNext();
    }
  }
}

class Button implements Range, Drawable {
  float x, y, w, h;
  
  public Button(float xx, float yy, float ww, float hh) {
    x = xx;
    y = yy;
    w = ww;
    h = hh;
  }
  
  void mouseMove(float xx, float yy) {
    
  }
  
  void mouseRelease(float xx, float yy) {
    if(xx > x && xx < x + w && yy > y && yy < y + h) {
      colorByAxis(findNearestAxis(xx));
    }
  }
  
  void mousePress(float xx, float yy){}
  
  void drawShape() {
    fill(250, 250, 250);
    stroke(0, 0, 0);
    strokeWeight(2);
    rect(x, y, w, h);
  }
  
  void resizeSelf(float ow, float oh, float nw, float nh) {
    x *= nw/ow;
    y *= nh/oh;
    w *= nw/ow;
    h *= nh/oh;
  }
}

class LineNode implements Drawable {
  LineNode next, prev;
  boolean highlighted, selected, locked;
  String name;
  Axis dad;
  float x, y, c, ov;
  
  public LineNode(String nam, float xx, float yy, LineNode p, LineNode n, Axis a) {
    name = nam;
    x = xx;
    y = yy;
    ov = yy;
    prev = p;
    next = n;
    dad = a;
    dad.newValue(yy);
    dad.addChild(this);
  }
  
  public LineNode(String nam, float xx, float yy) {
    name = nam;
    x = xx;
    y = yy;
  }
  
  public void unlock(int dir) {
    locked = false;
    if(dir == 1) {
      if(next != null) {
        next.unlock(1);
      }
    } else if(dir == -1) {
      if(prev != null) {
        prev.unlock(-1);
      }
    }
  }
  
  public void lock(int dir) {
    locked = true;
    if(dir == 1) {
      if(next != null) {
        next.lock(1);
      }
    } else if(dir == -1) {
      if(prev != null) {
        prev.lock(-1);
      }
    }
  }
  
  public void colorByAxis() {
    c = ((ov - dad.getTrueMin())/(dad.getTrueMax() - dad.getTrueMin()))*200 + 50;
    percolateColor(1, c);
    percolateColor(-1, c);
  }
  
  public void percolateColor(int dir, float col) {
    c = col;
    if(dir == 1) {
      if(next != null) {
        next.percolateColor(1, col);
      }
    } else if(dir == -1) {
      if(prev != null) {
        prev.percolateColor(-1, col);
      }
    }
  }
  
  public void select(int dir) {
    selected = true;
    if(dir == 1) {
      if(next != null) {
        next.select(1);
      }
    } else if(dir == -1) {
      if(prev != null) {
        prev.select(-1);
      }
    }
  }
  
  public void unselect(int dir) {
    selected = false;
    if(dir == 1) {
      if(next != null) {
        next.unselect(1);
      }
    } else if(dir == -1) {
      if(prev != null) {
        prev.unselect(-1);
      }
    }
  }
  
  public void setNext(LineNode ln) {
    next = ln;
    next.setPrev(this);
  }
  
  public void setPrev(LineNode ln) {
    prev = ln;
  }
  
  public void setAxis(Axis a) {
    dad = a;
  }
  
  public boolean isSelected() {
    return selected;
  }
  
  public boolean isHighlighted() {
    return highlighted;
  }
  
  public void highlight() {
    highlighted = true;
    if(next != null) {
      next.highlightForwards();
    }
    if(prev != null) {
      prev.highlightBackwards();
    }
  }
  
  public void highlightBackwards() {
    highlighted = true;
    if(prev != null) {
      prev.highlightBackwards();
    }
  }
  
  public void highlightForwards() {
    highlighted = true;
    if(next != null) {
      next.highlightForwards();
    }
  }
  
  public void unhighlight() {
    if(selected || locked) {
      return;
    }
    highlighted = false;
    if(next != null) {
      next.unhighlightForwards();
    }
    if(prev != null) {
      prev.unhighlightBackwards();
    }
  }
  
  public void unhighlightBackwards() {
    highlighted = false;
    if(prev != null) {
      prev.unhighlightBackwards();
    }
  }
  
  public void unhighlightForwards() {
    highlighted = false;
    if(next != null) {
      next.unhighlightForwards();
    }
  }
  
  public Axis getAxis() {
    return dad;
  }
  
  public float getX() {
    return x;
  }
  
  public float getY() {
    return y;
  }
  
  public float getYDraw() {
    return dad.getYValue(y);
  }
  
  public LineNode getNext() {
    return next;
  }
  
  public LineNode getPrev() {
    return prev;
  }
  
  void drawShape() {
    update();
    if(next != null) {
      strokeWeight(LINE_STROKE);
      if(highlighted) {
        if(selected) {
          stroke(0, 200, 200);
        } else {
          stroke(0, 200, 0);
        }
      } else {
        stroke(c, 0, c);
      }
      line(x, dad.getYValue(y), next.getX(), next.getAxis().getYValue(next.getY()));
      next.drawShape();
    }
    if(highlighted && !selected && findNearestAxis(mouseX) == dad) {
      if(tooltipLock == null || tooltipLock == this) {
        tooltipLock = this;
        fill(50, 50, 50);
        textFont(f2,fontSize*2);
        text(name, mouseX, mouseY - 20);
        text(ov, mouseX, mouseY);
        textFont(f,fontSize);
      }
    } else if(tooltipLock == this) {
      tooltipLock = null;
    }
  }
  
  void resizeSelf(float ow, float oh, float nw, float nh) {
    x *= nw/ow;
    y *= nw/ow;
    if(next != null) {
      next.resizeSelf(ow, oh, nw, nh);
    }
    dad.newValue(y);
  }
  
  void update() {
    
  }
}

class Axis implements Drawable, Range{
  float min, max, omin, omax, x, y, w, h, ys, xs;
  boolean flipped, resized, sliding;
  String label;
  ArrayList<LineNode> children = new ArrayList<LineNode>();
  
  public Axis(String lab, float xx, float yy) {
    label = lab;
    x = xx;
    y = yy;
    min = Integer.MAX_VALUE;
    max = Integer.MIN_VALUE;
    h = DATA_Y_END - DATA_Y_START;
    w = AXIS_WIDTH;
  }
  
  public void selectChildren() {
    for(int i = 0; i < children.size(); i++) {
      children.get(i).select(1);
      children.get(i).select(-1);
    }
  }
  
  public void unselectChildren() {
    for(int i = 0; i < children.size(); i++) {
      children.get(i).unselect(1);
      children.get(i).unselect(-1);
    }
  }
  
  public String getLabel() {
    return label;
  }
  
  public float getX() {
    return x - w/2;
  }
  
  public float getY() {
    return y;
  }
  
  public float getHeight() {
    return h;
  }
  
  public float getWidth() {
    return w;
  }
  
  public void colorChildren() {
    for(int i = 0; i < children.size(); i++) {
      children.get(i).colorByAxis();
    }
  }
  
  public float getTrueMin() {
    return omin;
  }
  
  public float getTrueMax() {
    return omax;
  }
  
  public void newValue(float val) {
    if(val < min) {
      min = val;
    }
    if(val > max) {
      max = val;
    }
    if(!resized) {
      omin = min;
      omax = max;
    }
  }
  
  public ArrayList<LineNode> getChildren() {
    return children;
  }
  
  public void addChild(LineNode n) {
    children.add(n);
  }
  
  public void flip() {
    flipped = !flipped;
  }
  
  float getYValue(float yy) {
    if(!flipped) {
      return y + h*(1 - (yy - min)/(max - min));
    }
    return y + h*(yy - min)/(max - min);
  }
  
  void resizeSelf(float ow, float oh, float nw, float nh) {
    resized = true;
    x *= nw/ow;
    y *= nh/oh;
    w *= nw/ow;
    h *= nh/oh;
    min = Integer.MAX_VALUE;
    max = Integer.MIN_VALUE;
  }
  
  void drawShape() {
    fill(200, 200, 200);
    stroke(0, 0, 200);
    strokeWeight(1);
    rect(x - w/2, y, w, h);
    
    fill(0, 0, 0);
    text(label, x - TEXT_XOFFSET, y - TEXT_YOFFSET*2);
    if(flipped) {
      text(omin, x - TEXT_XOFFSET, y - TEXT_YOFFSET);
      text(omax, x - TEXT_XOFFSET, y + h + TEXT_YOFFSET);
    } else {
      text(omax, x - TEXT_XOFFSET, y - TEXT_YOFFSET);
      text(omin, x - TEXT_XOFFSET, y + h + TEXT_YOFFSET);
    }
    fill(250, 250, 250);
  }
  
  void mouseMove(float xx, float yy) {
    
  }
  
  void mousePress(float xx, float yy) {
    if(xx > getX() && xx < getX() + w && yy > y && yy < y + h) {
      ys = yy;
      xs = xx;
    }
  }
  
  void mouseRelease(float xx, float yy) {
    if(xx > getX() - w/2 && xx < getX() + w && yy > y && yy < y + h) {
      if(Math.abs(ys - yy) < MIN_HRANGE) {
        flip();
      }
    }
  }
}