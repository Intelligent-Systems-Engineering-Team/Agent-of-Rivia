package env;

import jason.asSyntax.Literal;
import jason.asSyntax.Structure;
import jason.environment.Environment;

import java.util.Collection;
import java.util.Random;
import java.util.logging.Logger;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import static env.Direction.*;

/**
 * Any Jason environment "entry point" should extend
 * jason.environment.Environment class to override methods init(),
 * updatePercepts() and executeAction().
 */
public class Arena2DEnvironment extends Environment {

    private static final Random RAND = new Random();

    // action literals
    public static final Literal moveForward = Literal.parseLiteral("move(" + FORWARD.name().toLowerCase() + ")");
    public static final Literal moveRight = Literal.parseLiteral("move(" + RIGHT.name().toLowerCase() + ")");
    public static final Literal moveLeft = Literal.parseLiteral("move(" + LEFT.name().toLowerCase() + ")");
    public static final Literal moveBackward = Literal.parseLiteral("move(" + FORWARD.name().toLowerCase() + ")");
    public static final Literal moveRandom = Literal.parseLiteral("move(random)");

    static Logger logger = Logger.getLogger(Arena2DEnvironment.class.getName());

    private Arena2DModel model;
    private Arena2DView view;

    @Override
    public void init(final String[] args) {
        this.model = new Arena2DModelImpl(Integer.parseInt(args[0]), Integer.parseInt(args[1]));
        if (args.length > 2) {
            model.setSlideProbability(Double.parseDouble(args[2]));
        }
        Arena2DGuiView view = new Arena2DGuiView(model);
        this.view = view;
        view.setVisible(true);
    }

    private void notifyModelChangedToView() {
        view.notifyModelChanged();
    }

    private void initializeAgentIfNeeded(String agentName) {
        if (!model.containsAgent(agentName)) {
            model.setAgentPoseRandomly(agentName);
            view.notifyModelChanged();
        }
    }

    @Override
    public Collection<Literal> getPercepts(String agName) {
        initializeAgentIfNeeded(agName);
        return Stream.of(
                surroundingPercepts(agName),
                neighboursPercepts(agName)
        ).flatMap(Collection::stream)
        .collect(Collectors.toList());

    }

    private Literal proximityPerceptFor(Direction direction, Vector2D position) {
        if (model.getAgentByPosition(position).isPresent()) {
            return Literal.parseLiteral(String.format("robot(%s)", direction.name().toLowerCase()));
        } else if (model.isPositionOutside(position)) {
            return Literal.parseLiteral(String.format("obstacle(%s)", direction.name().toLowerCase()));
        } else {
            return Literal.parseLiteral(String.format("free(%s)", direction.name().toLowerCase()));
        }
    }

    private Collection<Literal> surroundingPercepts(String agent) {
        return model.getAgentSurroundingPositions(agent)
                .entrySet().stream()
                .map(it -> proximityPerceptFor(it.getKey(), it.getValue()))
                .collect(Collectors.toList());
    }

    private Collection<Literal> neighboursPercepts(String agent) {
        return model.getAgentNeighbours(agent).stream()
                .map(it -> String.format("neighbour(%s)", it))
                .map(Literal::parseLiteral)
                .collect(Collectors.toList());
    }

    /**
     * The <code>boolean</code> returned represents the action "move"
     * (success/failure)
     */
    @Override
    public boolean executeAction(final String ag, final Structure action) {
        initializeAgentIfNeeded(ag);
        final boolean result;
        if (RAND.nextDouble() < model.getSlideProbability()) {
            result = false;
        } else if (action.equals(moveForward)) {
            result = model.moveAgent(ag, 1, FORWARD);
        } else if (action.equals(moveRight)) {
            result = model.moveAgent(ag, 1, RIGHT);
        } else if (action.equals(moveBackward)) {
            result = model.moveAgent(ag, 1, BACKWARD);
        } else if (action.equals(moveLeft)) {
            result = model.moveAgent(ag, 1, LEFT);
        } else if (action.equals(moveRandom)) {
            Direction rd = Direction.random();
            result = model.moveAgent(ag, 1, rd);
        } else {
            RuntimeException e = new IllegalArgumentException("Cannot handle action: " + action);
            logger.warning(e.getMessage());
            throw e;
        }
        try {
            Thread.sleep(1000L / model.getFPS());
        } catch (InterruptedException ignored) { }
        notifyModelChangedToView();
        return result;
    }
}
