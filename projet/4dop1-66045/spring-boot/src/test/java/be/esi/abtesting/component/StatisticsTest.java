package be.esi.abtesting.component;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class StatisticsTest {

    @Test
    void testInitialValue() {
        Statistics stats = new Statistics();
        assertEquals(0, stats.getViewCount());
    }

    @Test
    void testIncrementView() {
        Statistics stats = new Statistics();
        stats.incrementView();
        assertEquals(1, stats.getViewCount());
    }

    @Test
    void testMultipleIncrements() {
        Statistics stats = new Statistics();

        stats.incrementView();
        stats.incrementView();
        stats.incrementView();

        assertEquals(3, stats.getViewCount());
    }
}
