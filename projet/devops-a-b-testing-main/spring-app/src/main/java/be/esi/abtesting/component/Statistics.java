package be.esi.abtesting.component;

import org.springframework.stereotype.Component;

@Component
public class Statistics {
    private int viewCount;

    public Statistics(){
    }
    
    public int getViewCount() {
        return viewCount;
    }

    public void incrementView() { 
        viewCount++; 
    }

}
