package env;
import jason.asSyntax.Literal;
import jason.asSyntax.Structure;
import jason.environment.Environment;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Random;
import java.util.logging.Logger;
import java.util.stream.Collectors;

import static env.Direction.*;

/**
 * Any Jason environment "entry point" should extend
 * jason.environment.Environment class to override methods init(),
 * updatePercepts() and executeAction().
 */
public class Arena2DEnvironment extends Environment {

    public static final Literal moveForward = Literal.parseLiteral("move(" + FORWARD.name().toLowerCase() + ")");
    public static final Literal moveRight = Literal.parseLiteral("move(" + RIGHT.name().toLowerCase() + ")");
    public static final Literal moveLeft = Literal.parseLiteral("move(" + LEFT.name().toLowerCase() + ")");
    public static final Literal moveBackward = Literal.parseLiteral("move(" + BACKWARD.name().toLowerCase() + ")");
    public static final Literal moveRandom = Literal.parseLiteral("move(random)");

    private Arena2DModel model;
    private Arena2DView view;

    static Logger logger = Logger.getLogger(Arena2DEnvironment.class.getName());
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

        if ("witcher".equals(agentName)) {
            percepts.addAll(getMonsterLocationPercepts());
        } else {
            percepts.add(getMonsterSelfPercepts(agentName));
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


    private Collection<Literal> getMonsterLocationPercepts() {
        return model.getAllAgents().stream()
                .filter(name -> !name.equals("witcher"))
                .filter(name -> model.getAgentAliveStatus(name) != null)
                .map(name -> {
                    Vector2D pos = model.getAgentPosition(name);
                    MonsterStats stats = model.getMonsterStats(name);
                    String status = model.getAgentAliveStatus(name).toString().toLowerCase();

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


    private Literal getMonsterSelfPercepts(String agentName) {
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
        return agentName.equals("witcher");
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
        return (x == 0 && y == 0) || (x == model.getWidth() - 1 && y == 0);
    }


    private Literal proximityPerceptFor(Direction direction, Vector2D position) {
        String directionName = direction.name().toLowerCase();

        if (model.isPositionOutside(position)) {
            return Literal.parseLiteral(String.format("obstacle(%s)", directionName));
        }

        if (model.getAgentByPosition(position).isPresent()) {
            return Literal.parseLiteral(String.format("robot(%s)", directionName));
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
        if (action.equals(moveForward)) {
            return model.moveAgent(agentName, 1, FORWARD);
        }

        if (action.equals(moveRight)) {
            return model.moveAgent(agentName, 1, RIGHT);
        }

        if (action.equals(moveBackward)) {
            return model.moveAgent(agentName, 1, BACKWARD);
        }

        if (action.equals(moveLeft)) {
            return model.moveAgent(agentName, 1, LEFT);
        }

        if (action.equals(moveRandom)) {
            return model.moveAgent(agentName, 1, Direction.random());
        }

        if (action.getFunctor().equals("turn")) {
            return handleTurn(agentName, action);
        }

        if (action.getFunctor().equals("kill")) {
            return handleKill(action);
        }

        if (action.getFunctor().equals("apply_damage")) {
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
        String monsterName = action.getTerm(0).toString();
        return model.setAgentDead(monsterName);
    }


    private boolean handleApplyDamage(String agentName, Structure action) {
        int damage = Integer.parseInt(action.getTerm(0).toString());

        boolean result = model.applyDamage(agentName, damage);

        MonsterStats stats = model.getMonsterStats(agentName);
        if (stats.health() == 0) {
            logger.info(agentName + " died.");
        } else {
            logger.info(agentName + " took " + damage + " damage. HP now: " + stats.health());
        }

        return result;
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
        logger.warning(e.getMessage());
        throw e;
    }


    private void notifyModelChangedToView() {
        view.notifyModelChanged();
    }
}