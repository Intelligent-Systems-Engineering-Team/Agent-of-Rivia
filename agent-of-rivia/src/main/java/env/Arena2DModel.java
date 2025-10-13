package env;

import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;
import java.util.stream.Stream;

public interface Arena2DModel {

    /** Checks whether an agent with the given name exists in the environment */
    boolean containsAgent(String name);

    /** Retrieves the set of agent identifiers of all the agents currently existing into the environment */
    Set<String> getAllAgents();

    /** Retrieves the width of the environment */
    int getWidth();

    /** Retrieves the height of the environment */
    int getHeight();

    /** Checks whether a given position is inside the environment, given its coordinates */
    boolean isPositionInside(int x, int y);

    /** Checks whether a given position is inside the environment */
    default boolean isPositionInside(Vector2D position) {
        return isPositionInside(position.getX(), position.getY());
    }

    /** Checks whether a given position is outside the environment, given its coordinates */
    default boolean isPositionOutside(int x, int y) {
        return !isPositionInside(x, y);
    }

    /** Checks whether a given position is outside the environment */
    default boolean isPositionOutside(Vector2D position) {
        return isPositionOutside(position.getX(), position.getY());
    }

    /** Retrieves an agent's absolute position in the environment, given its name */
    Vector2D getAgentPosition(String agent);

    /** Retrieves an agent name's given its absolute position, or nothing, if no agent is present in the provided position */
    Optional<String> getAgentByPosition(Vector2D position);

    /** Retrieves an agent absolute orientation given its name */
    Orientation getAgentDirection(String agent);

    /** Updates an agent's pose (absolute position + absolute orientation), given its name and coordinates */
    boolean setAgentPose(String agent, int x, int y, Orientation orientation);

    /** Updates an agent's pose (absolute position + absolute orientation), given its name */
    default boolean setAgentPose(String agent, Vector2D position, Orientation orientation) {
        return setAgentPose(agent, position.getX(), position.getY(), orientation);
    }

    /** Puts an agent (selected by name) into a random pose (absolute position + absolute orientation) */
    default boolean setAgentPoseRandomly(String agent) {
        return setAgentPose(agent, Vector2D.random(getWidth(), getHeight()), Orientation.random());
    }

    /** Moves an agent (selected by name) of a given amount of steps in a relative direction */
    default boolean moveAgent(String agent, int stepSize, Direction direction) {
        final Orientation newOrientation = getAgentDirection(agent).rotate(direction);
        return setAgentPose(agent, getAgentPosition(agent).afterStep(stepSize, newOrientation), newOrientation);
    }

    /** Checks whether two agents are close to each others, given their names */
    boolean areAgentsNeighbours(String agent, String neighbour);

    /** Gets the set of all the agents which are close to the provided one  */
    default Set<String> getAgentNeighbours(String agent) {
        return getAllAgents().stream()
                .filter(it -> !it.equals(agent))
                .filter(other -> areAgentsNeighbours(agent, other))
                .collect(Collectors.toSet());
    }

    /** Retrieves the actual positions surrounding an agent, indexed by relative direction  */
    default Map<Direction, Vector2D> getAgentSurroundingPositions(String agent) {
        Vector2D pos = getAgentPosition(agent);
        Orientation dir = getAgentDirection(agent);
        return Stream.of(Direction.values()).collect(Collectors.toMap(
                k -> k,
                v -> pos.afterStep(1, dir.rotate(v))
        ));
    }

    /** Get the frame-per-second value to be used by any view of the system */
    long getFPS();
    void setFPS(long fps);

    /** Gets the sliding probability for the current environment */
    double getSlideProbability();
    void setSlideProbability(double value);
}
