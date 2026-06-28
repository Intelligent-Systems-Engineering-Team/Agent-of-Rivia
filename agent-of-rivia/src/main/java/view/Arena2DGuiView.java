package view;

import model.Arena2DModel;
import model.MonsterStatus;
import model.Orientation;
import model.Vector2D;

import javax.swing.*;
import java.awt.*;
import java.lang.reflect.InvocationTargetException;
import java.util.HashMap;
import java.util.Map;
import java.util.Objects;
import java.util.Random;

public class Arena2DGuiView extends JFrame implements Arena2DView {

    private static final Random RAND = new Random();

    private static final int DEATH_ANIMATION_DURATION_MS = 2000;
    private static final String HOME_SYMBOL = "H";
    private static final String TAVERN_SYMBOL = "T";


    private static Color randomColor() {
        float hue;

        do {
            hue = RAND.nextFloat();
        } while (hue >= 0.30f && hue <= 0.38f);

        float saturation = 0.75f + RAND.nextFloat() * 0.25f;
        float brightness = 0.80f + RAND.nextFloat() * 0.20f;

        return Color.getHSBColor(hue, saturation, brightness);
    }


    private static Color negateColor(Color color) {
        return new Color(255 - color.getRed(), 255 - color.getGreen(), 255 - color.getBlue(), color.getAlpha());
    }


    private final Arena2DModel model;
    private final Map<Vector2D, JButton> buttonsGrid = new HashMap<>();
    private final Map<String, Color> agentColors = new HashMap<>();

    private final JLabel deathCounterLabel = new JLabel();

    private int lastDeathCount = 0;
    private long witcherRedUntilMillis = 0;


    public Arena2DGuiView(Arena2DModel model) {
        this.model = Objects.requireNonNull(model);

        JPanel contentPane = new JPanel(new BorderLayout());

        deathCounterLabel.setHorizontalAlignment(SwingConstants.CENTER);
        deathCounterLabel.setFont(deathCounterLabel.getFont().deriveFont(Font.BOLD, 16f));
        contentPane.add(deathCounterLabel, BorderLayout.NORTH);

        JPanel grid = new JPanel(new GridLayout(model.getHeight(), model.getWidth()));
        for (int y = 0; y < model.getHeight(); y++) {
            for (int x = 0; x < model.getWidth(); x++) {
                JButton b = new JButton("   ");
                grid.add(b);
                buttonsGrid.put(Vector2D.of(x, y), b);
            }
        }

        contentPane.add(grid, BorderLayout.CENTER);
        JSlider slider = new JSlider(JSlider.HORIZONTAL, 1, 60, (int) model.getFPS());
        contentPane.add(slider, BorderLayout.SOUTH);
        slider.addChangeListener(e -> model.setFPS(slider.getValue()));
        setContentPane(contentPane);
        pack();
    }


    private Color getColorForAgent(String agentName) {
        if (agentName.equals(model.getHeroName())) {
            if (System.currentTimeMillis() < witcherRedUntilMillis) {
                return Color.RED;
            }
            return Color.GREEN;
        }

        return agentColors.computeIfAbsent(agentName, k -> randomColor());
    }


    @Override
    public Arena2DModel getModel() {
        return model;
    }


    private void updateView() {
        updateDeathAnimation();
        updateDeathCounterLabel();
        clearGrid();
        drawMapObjects();
        drawAgents();
        repaint();
    }


    private void updateDeathAnimation() {
        int currentDeathCount = model.getDeathCount();

        if (currentDeathCount > lastDeathCount) {
            int curDeathLength = DEATH_ANIMATION_DURATION_MS / (int) model.getFPS();
            witcherRedUntilMillis = System.currentTimeMillis() + curDeathLength;

            Timer timer = new Timer(curDeathLength, e -> updateView());
            timer.setRepeats(false);
            timer.start();
        }

        lastDeathCount = currentDeathCount;
    }


    private void updateDeathCounterLabel() {
        deathCounterLabel.setText("Deaths: " + model.getDeathCount());
    }


    private void clearGrid() {
        buttonsGrid.values().forEach(b -> {
            b.setText(" ");
            b.setBackground(Color.WHITE);
            b.setForeground(UIManager.getColor("Button.foreground"));
            b.setEnabled(true);
        });
    }


    private void drawMapObjects() {
        buttonsGrid.get(model.getHomePosition()).setText(HOME_SYMBOL);
        buttonsGrid.get(model.getTavernPosition()).setText(TAVERN_SYMBOL);
    }


    private void drawAgents() {
        model.getAllAgents().forEach(a -> {
            if (model.getAgentStatus(a) == MonsterStatus.DEAD) {
                return;
            }
            Vector2D pos = model.getAgentPosition(a);
            Orientation dir = model.getAgentDirection(a);
            JButton b = buttonsGrid.get(pos);
            b.setText(dir.getSymbol());
            Color c = getColorForAgent(a);
            b.setBackground(c);
            b.setForeground(negateColor(c));
            b.setEnabled(false);
        });
    }


    @Override
    public void notifyModelChanged() {
        try {
            SwingUtilities.invokeAndWait(this::updateView);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        } catch (InvocationTargetException e) {
            System.err.println(e.getCause().getMessage());
        }
    }
}