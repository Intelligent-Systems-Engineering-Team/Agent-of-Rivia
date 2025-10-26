package utils;

import env.Direction;
import env.Vector2D;
import jason.asSyntax.Atom;
import jason.asSyntax.Literal;
import jason.asSyntax.Term;

enum Facing {
    TOP(0, -1),
    RIGHT(1, 0),
    BOTTOM(0, 1),
    LEFT(-1, 0);

    Facing(int x, int y) {
        this.x = x;
        this.y = y;
    }

    static Facing fromLiteral(Literal literal) {
        return fromTerm(literal.getTerm(0));
    }

    static Facing fromTerm(Term term) {
        if (!term.isAtom()) {
            throw new IllegalArgumentException("Cannot parse as Facing: " + term);
        }
        return valueOf(((Atom) term).getFunctor().toUpperCase());
    }

    private final int x, y;

    public int getX() {
        return x;
    }

    public int getY() {
        return y;
    }



    public static Facing rotate(Facing currentFacing, Direction direction) {
        switch (direction) {
            case FORWARD:
                return currentFacing; // не меняем направление
            case BACKWARD:
                return currentFacing.opposite(); // поворот на 180°
            case LEFT:
                return currentFacing.turnLeft(); // поворот на 90° влево
            case RIGHT:
                return currentFacing.turnRight(); // поворот на 90° вправо
            default:
                return currentFacing;
        }
    }

    public Facing turnLeft() {
        switch (this) {
            case TOP: return LEFT;
            case LEFT: return BOTTOM;
            case BOTTOM: return RIGHT;
            case RIGHT: return TOP;
            default: throw new IllegalStateException("Unknown facing: " + this);
        }
    }

    public Facing turnRight() {
        switch (this) {
            case TOP: return RIGHT;
            case RIGHT: return BOTTOM;
            case BOTTOM: return LEFT;
            case LEFT: return TOP;
            default: throw new IllegalStateException("Unknown facing: " + this);
        }
    }

    public Facing opposite() {
        switch (this) {
            case TOP: return BOTTOM;
            case BOTTOM: return TOP;
            case LEFT: return RIGHT;
            case RIGHT: return LEFT;
            default: throw new IllegalStateException("Unknown facing: " + this);
        }
    }



    public Vector2D asVector() {
        return Vector2D.of(x, y);
    }
}
