package env;

import javax.swing.text.html.Option;
import java.util.*;
import java.util.function.BiFunction;

public class Arena2DModelImpl implements Arena2DModel {

    private static class Pose {
        private final Vector2D position;
        private final Orientation orientation;

        public Pose(Vector2D position, Orientation orientation) {
            this.position = Objects.requireNonNull(position);
            this.orientation = Objects.requireNonNull(orientation);
        }

        public Vector2D getPosition() {
            return position;
        }

        public Orientation getOrientation() {
            return orientation;
        }


        @Override
        public boolean equals(Object o) {
            if (this == o) return true;
            if (o == null || getClass() != o.getClass()) return false;
            Pose pose = (Pose) o;
            return position.equals(pose.position) &&
                    orientation == pose.orientation;
        }

        @Override
        public int hashCode() {
            return Objects.hash(position, orientation);
        }

        @Override
        public String toString() {
            return "Pose{" +
                    "position=" + position +
                    ", direction=" + orientation +
                    '}';
        }
    }

    private final Map<String, Pose> agentPoses = Collections.synchronizedMap(new HashMap<>());
    private final int width;
    private final int height;
    private final BiFunction<Vector2D, Vector2D, Boolean> neighbourhoodFunction;
    private long fsp = 1L;
    private double slideProbability = 0d;

    public Arena2DModelImpl(int width, int height) {
        this(width, height, (a, b) -> {
            Vector2D distanceVector = b.minus(a);
            return Math.abs(distanceVector.getX()) <= 1 && Math.abs(distanceVector.getY()) <= 1;
        });
    }

    public Arena2DModelImpl(int width, int height, BiFunction<Vector2D, Vector2D, Boolean> neighbourhoodFunction) {
        this.width = width;
        this.height = height;
        this.neighbourhoodFunction = Objects.requireNonNull(neighbourhoodFunction);
    }

    @Override
    public boolean containsAgent(String name) {
        return agentPoses.containsKey(name);
    }

    @Override
    public Set<String> getAllAgents() {
        return agentPoses.keySet();
    }

    @Override
    public int getWidth() {
        return width;
    }

    @Override
    public int getHeight() {
        return height;
    }

    @Override
    public boolean isPositionInside(int x, int y) {
        return x >= 0 && x < width && y >= 0 && y < height ;
    }

    private void ensureAgentExists(String agent) {
        if (!containsAgent(agent)) {
            throw new IllegalArgumentException("No such an agent: " + agent);
        }
    }

    @Override
    public Vector2D getAgentPosition(String agent) {
        synchronized (agentPoses) {
            ensureAgentExists(agent);
            return agentPoses.get(agent).getPosition();
        }
    }

    @Override
    public Orientation getAgentDirection(String agent) {
        synchronized (agentPoses) {
            ensureAgentExists(agent);
            return agentPoses.get(agent).getOrientation();
        }
    }

    private void setAgentPosition(String agent, Vector2D position) {
        synchronized (agentPoses) {
            Pose currentPose = agentPoses.get(agent);
            agentPoses.put(agent, new Pose(position, currentPose.getOrientation()));
        }
    }

    private void setAgentDirection(String agent, Orientation orientation) {
        synchronized (agentPoses) {
            Pose currentPose = agentPoses.get(agent);
            agentPoses.put(agent, new Pose(currentPose.getPosition(), orientation));
        }
    }

    @Override
    public Optional<String> getAgentByPosition(Vector2D position) {
        synchronized (agentPoses) {
            return agentPoses.entrySet().stream()
                    .filter(it -> it.getValue().getPosition() == position)
                    .map(Map.Entry::getKey)
                    .findFirst();
        }
    }

    @Override
    public boolean setAgentPose(String agent, int x, int y, Orientation orientation) {
        synchronized (agentPoses) {
            if (containsAgent(agent)) {
                setAgentDirection(agent, orientation);
                if (isPositionInside(x, y)) {
                    Vector2D position = Vector2D.of(x, y);
                    if (!getAgentByPosition(position).isPresent()) {
                        setAgentPosition(agent, position);
                        return true;
                    }
                }
                return false;
            }
            agentPoses.put(agent, new Pose(Vector2D.of(x, y), orientation));
            return true;
        }
    }

    @Override
    public boolean areAgentsNeighbours(String agent, String neighbour) {
        if (!containsAgent(agent) || !containsAgent(neighbour)) return  false;
        Vector2D agentPosition = getAgentPosition(agent);
        Vector2D neighbourPosition = getAgentPosition(neighbour);
        return neighbourhoodFunction.apply(agentPosition, neighbourPosition);
    }

    @Override
    public long getFPS() {
        return fsp;
    }

    @Override
    public void setFPS(long fps) {
        this.fsp = Math.max(Math.min(60, fps), 1);
    }

    @Override
    public double getSlideProbability() {
        return slideProbability;
    }

    @Override
    public void setSlideProbability(double slideProbability) {
        this.slideProbability = Math.max(Math.min(1d, slideProbability), 0d);;
    }
}
