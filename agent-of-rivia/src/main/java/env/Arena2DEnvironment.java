package env;
import jason.asSyntax.Literal;
import jason.asSyntax.Structure;
import jason.environment.Environment;
import model.*;
import view.Arena2DGuiView;
import view.Arena2DView;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Random;
import java.util.logging.Logger;
import java.util.stream.Collectors;

import static model.Direction.*;

/**
 * Any Jason environment "entry point" should extend
 * jason.environment.Environment class to override methods init(),
 * updatePercepts() and executeAction().
 */
public class Arena2DEnvironment extends Environment {

    private static final Literal ACTION_MOVE_FORWARD = Literal.parseLiteral("move(forward)");
    private static final Literal ACTION_MOVE_RIGHT = Literal.parseLiteral("move(right)");
    private static final Literal ACTION_MOVE_LEFT = Literal.parseLiteral("move(left)");
    private static final Literal ACTION_MOVE_BACKWARD = Literal.parseLiteral("move(backward)");
    private static final Literal ACTION_MOVE_RANDOM = Literal.parseLiteral("move(random)");

    private static final String ACTION_TURN = "turn";
    private static final String ACTION_KILL = "kill";
    private static final String ACTION_APPLY_DAMAGE = "apply_damage";

    private Arena2DModel model;
    private Arena2DView view;

    private static final Logger LOGGER = Logger.getLogger(Arena2DEnvironment.class.getName());
    private static final Random RAND = new Random();


    @Override
    public void init(final String[] args) {
        this.model = new Arena2DModelImpl(Integer.parseInt(args[0]), Integer.parseInt(args[1]));
        Arena2DGuiView view = new Arena2DGuiView(model);
        this.view = view;
        view.setVisible(true);
    }


    @Override
    public Collection<Literal> getPercepts(String agentName) {
        initializeAgentIfNeeded(agentName);

        Collection<Literal> percepts = new ArrayList<>();

        percepts.addAll(surroundingPercepts(agentName));
        percepts.addAll(neighboursPercepts(agentName));

        if (agentName.equals(model.getHeroName())) {
            percepts.add(mapPositionPercept("home", model.getHomePosition()));
            percepts.add(mapPositionPercept("tavern", model.getTavernPosition()));
            percepts.addAll(getMonsterLocationPercepts());
        } else {
            percepts.add(getMonsterSelfPercept(agentName));
        }
        return percepts;
    }


    private Collection<Literal> surroundingPercepts(String agentName) {
        return model.getAgentSurroundingPositions(agentName)
                .entrySet().stream()
                .map(it -> proximityPerceptFor(it.getKey(), it.getValue()))
                .collect(Collectors.toList());
    }


    private Collection<Literal> neighboursPercepts(String agentName) {
        return model.getAgentNeighbours(agentName).stream()
                .map(it -> String.format("neighbour(%s)", it))
                .map(Literal::parseLiteral)
                .collect(Collectors.toList());
    }


    private Literal mapPositionPercept(String name, Vector2D position) {
        return Literal.parseLiteral(String.format(
                "%s(%d,%d)",
                name,
                position.getX(),
                position.getY()
        ));
    }


    private Collection<Literal> getMonsterLocationPercepts() {
        return model.getAllAgents().stream()
                .filter(name -> !name.equals(model.getHeroName()))
                .filter(name -> model.getAgentStatus(name) != null)
                .map(name -> {
                    Vector2D pos = model.getAgentPosition(name);
                    MonsterStats stats = model.getMonsterStats(name);
                    String status = model.getAgentStatus(name).toString().toLowerCase();

                    return Literal.parseLiteral(String.format(
                            "monster(%s,%s,%d,%d,%s)",
                            name,
                            stats.type(),
                            pos.getX(),
                            pos.getY(),
                            status
                    ));
                })
                .collect(Collectors.toList());
    }


    private Literal getMonsterSelfPercept(String agentName) {
        MonsterStats stats = model.getMonsterStats(agentName);
        return Literal.parseLiteral(String.format(
                "self_stats(%d,%d)",
                stats.health(),
                stats.strength()
        ));
    }


    private void initializeAgentIfNeeded(String agentName) {
        if (model.containsAgent(agentName)) {
            return;
        }

        if (isWitcher(agentName)) {
            initializeWitcher(agentName);
        } else {
            initializeMonster(agentName);
        }

        view.notifyModelChanged();
    }


    private boolean isWitcher(String agentName) {
        return agentName.equals(model.getHeroName());
    }


    private void initializeWitcher(String agentName) {
        model.setAgentPose(agentName, 0, 0, Orientation.NORTH);
    }


    private void initializeMonster(String agentName) {
        Vector2D spawnPosition = randomMonsterSpawnPosition();

        model.setAgentPose(agentName, spawnPosition, Orientation.NORTH);
        model.setAgentAlive(agentName);

        MonsterType spec = MonsterType.fromAgentName(agentName);
        model.setMonsterStats(agentName, spec.type(), spec.health(), spec.strength());
    }


    private Vector2D randomMonsterSpawnPosition() {
        int x;
        int y;

        do {
            x = RAND.nextInt(model.getWidth());
            y = RAND.nextInt(model.getHeight());
        } while (isReservedSpawnPosition(x, y));

        return Vector2D.of(x, y);
    }


    private boolean isReservedSpawnPosition(int x, int y) {
        Vector2D position = Vector2D.of(x, y);
        return position.equals(model.getHomePosition())
                || position.equals(model.getTavernPosition());
    }


    private Literal proximityPerceptFor(Direction direction, Vector2D position) {
        String directionName = direction.name().toLowerCase();

        if (model.isPositionOutside(position)) {
            return Literal.parseLiteral(String.format("obstacle(%s)", directionName));
        }

        return Literal.parseLiteral(String.format("free(%s)", directionName));
    }


    /**
     * The <code>boolean</code> returned represents the action "move"
     * (success/failure)
     */
    @Override
    public boolean executeAction(final String agentName, final Structure action) {
        initializeAgentIfNeeded(agentName);

        boolean result = handleAction(agentName, action);

        sleepOneFrame();
        notifyModelChangedToView();

        return result;
    }


    private boolean handleAction(String agentName, Structure action) {
        if (action.equals(ACTION_MOVE_FORWARD)) {
            return model.moveAgent(agentName, 1, FORWARD);
        }

        if (action.equals(ACTION_MOVE_RIGHT)) {
            return model.moveAgent(agentName, 1, RIGHT);
        }

        if (action.equals(ACTION_MOVE_BACKWARD)) {
            return model.moveAgent(agentName, 1, BACKWARD);
        }

        if (action.equals(ACTION_MOVE_LEFT)) {
            return model.moveAgent(agentName, 1, LEFT);
        }

        if (action.equals(ACTION_MOVE_RANDOM)) {
            return model.moveAgent(agentName, 1, Direction.random());
        }

        if (action.getFunctor().equals(ACTION_TURN)) {
            return handleTurn(agentName, action);
        }

        if (action.getFunctor().equals(ACTION_KILL)) {
            return handleKill(action);
        }

        if (action.getFunctor().equals(ACTION_APPLY_DAMAGE)) {
            return handleApplyDamage(agentName, action);
        }

        throwUnsupportedAction(action);
        return false;
    }


    private boolean handleTurn(String agentName, Structure action) {
        Direction direction = Direction.valueOf(
                action.getTerm(0).toString().toUpperCase()
        );

        Vector2D position = model.getAgentPosition(agentName);
        Orientation newOrientation = model.getAgentDirection(agentName).rotate(direction);

        return model.setAgentPose(agentName, position, newOrientation);
    }


    private boolean handleKill(Structure action) {
        String agentName = action.getTerm(0).toString();

        if (agentName.equals(model.getHeroName())) {
            model.incrementDeathCounter();
            return true;
        }

        model.setAgentDead(agentName);
        return true;
    }


    private boolean handleApplyDamage(String agentName, Structure action) {
        int damage = Integer.parseInt(action.getTerm(0).toString());

        model.applyDamage(agentName, damage);

        MonsterStats stats = model.getMonsterStats(agentName);
        if (stats.health() == 0) {
            LOGGER.info(agentName + " died.");
        } else {
            LOGGER.info(agentName + " took " + damage + " damage. HP now: " + stats.health());
        }
        return true;
    }


    private void sleepOneFrame() {
        try {
            Thread.sleep(1000L / model.getFPS());
        } catch (InterruptedException ignored) {
            Thread.currentThread().interrupt();
        }
    }


    private void throwUnsupportedAction(Structure action) {
        RuntimeException e = new IllegalArgumentException("Cannot handle action: " + action);
        LOGGER.warning(e.getMessage());
        throw e;
    }


    private void notifyModelChangedToView() {
        view.notifyModelChanged();
    }
}