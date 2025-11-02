package utils;

import java.util.Random;
import java.util.ArrayList;
import java.util.List;

public class MonsterGenerator {
    private final int arenaWidth;
    private final int arenaHeight;
    private final Random random = new Random();

    public MonsterGenerator(int width, int height) {
        this.arenaWidth = width;
        this.arenaHeight = height;
    }

    public List<int[]> generateMonsters(int count) {
        List<int[]> monsters = new ArrayList<>();
        for (int i = 0; i < count; i++) {
            int x = random.nextInt(arenaWidth);
            int y = random.nextInt(arenaHeight);
            monsters.add(new int[]{x, y});
        }
        return monsters;
    }
}
