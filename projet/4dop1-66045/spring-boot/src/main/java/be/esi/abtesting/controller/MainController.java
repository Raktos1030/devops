package be.esi.abtesting.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

import be.esi.abtesting.component.Statistics;

@Controller
public class MainController {

    @Autowired
    private Statistics stats;

    @GetMapping("/")
    public String index(Model model) {
        stats.incrementView();
        model.addAttribute("stats", stats);
        return "index";
    }
}
