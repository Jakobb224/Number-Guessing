/* window.vala
 *
 * Copyright 2026 Jakob Kokel
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

[GtkTemplate (ui = "/org/gnome/number_game/window.ui")]
public class Guesanumber.Window : Adw.ApplicationWindow {
    [GtkChild] private unowned Gtk.Button guess_button;
    [GtkChild] private unowned Gtk.Button reset_button;
    [GtkChild] private unowned Gtk.Button stats_button;
    [GtkChild] private unowned Gtk.Label score_label;
    [GtkChild] private unowned Gtk.SpinButton guess_spin_button;
    [GtkChild] private unowned Adw.StatusPage status_page;

    private int target_number;
    private int wins = 0;
    private int losses = 0;
    private string save_path;

    public Window (Gtk.Application app) {
        Object (application: app);

        save_path = Path.build_filename(Environment.get_user_data_dir(), "guesanumber_stats.dat");
        load_stats();
        update_score_ui();

        start_new_game();

        guess_button.clicked.connect (() => {
            int guess = (int)guess_spin_button.get_value();
            guess_button.visible = false;
            reset_button.visible = true;

            if (guess == target_number) {
                wins++;
                status_page.title = "Correct!";
                status_page.description = @"Bingo! $target_number was the right choice.";
                status_page.icon_name = "daytime-sunrise-symbolic";
            } else {
                losses++;
                status_page.title = "Wrong!";
                status_page.description = @"The number I wanted was $target_number.";
                status_page.icon_name = "dialog-error-symbolic";
            }
            save_stats();
            update_score_ui();
        });

        reset_button.clicked.connect (() => start_new_game());
        stats_button.clicked.connect (() => show_stats_sheet());
    }

    private void start_new_game() {
        target_number = Random.int_range(1, 11);
        status_page.title = "Good Luck!";
        status_page.description = "I search an Number between 1 ... 10";
        status_page.icon_name = "input-gaming-symbolic";
        guess_button.visible = true;
        reset_button.visible = false;
    }

    private void update_score_ui() {
        score_label.label = wins.to_string();
    }

    private void show_stats_sheet() {
        // Wir erstellen einen modernen Adw.Dialog
        var dialog = new Adw.Dialog();
        dialog.title = "Game Statistics";

        // Das sorgt dafür, dass er auf dem Desktop ein Dialog ist,
        // aber auf schmalen Fenstern/Mobile wie ein Bottom Sheet aussieht.
        dialog.presentation_mode = Adw.DialogPresentationMode.FLOATING;

        var content = new Gtk.Box(Gtk.Orientation.VERTICAL, 24);
        content.margin_bottom = 32;
        content.margin_top = 24;
        content.margin_start = 24;
        content.margin_end = 24;

        var title_label = new Gtk.Label("Performance");
        title_label.add_css_class("title-1");
        content.append(title_label);

        int total = wins + losses;

        // Das Diagramm-Widget
        var chart_area = new Gtk.DrawingArea();
        chart_area.set_size_request(300, 200);

        chart_area.set_draw_func((area, cr, width, height) => {
            if (total == 0) {
                cr.set_source_rgba(0.5, 0.5, 0.5, 0.5);
                cr.select_font_face("Sans", Cairo.FontSlant.NORMAL, Cairo.FontWeight.NORMAL);
                cr.set_font_size(14.0);
                cr.move_to(width / 4, height / 2);
                cr.show_text("No games played yet");
                return;
            }

            double padding = 30.0;
            double bar_spacing = 40.0;
            double bar_width = (width - (padding * 2) - bar_spacing) / 2.0;
            double max_val = (double)int.max(wins, losses);
            if (max_val == 0) max_val = 1.0;

            double scale = (height - padding * 2.5) / max_val;

            // WINS Balken
            double wins_h = wins * scale;
            cr.set_source_rgba(0.15, 0.75, 0.35, 1.0);
            draw_rounded_rect(cr, padding, height - padding - wins_h, bar_width, wins_h, 8);
            cr.fill();

            // LOSSES Balken
            double losses_h = losses * scale;
            cr.set_source_rgba(0.85, 0.25, 0.25, 1.0);
            draw_rounded_rect(cr, padding + bar_width + bar_spacing, height - padding - losses_h, bar_width, losses_h, 8);
            cr.fill();

            // Texte innerhalb der Zeichenfläche
            cr.set_source_rgba(0.5, 0.5, 0.5, 1.0);
            cr.set_font_size(14.0);
            cr.move_to(padding + 5, height - 10);
            cr.show_text(@"Wins: $wins");
            cr.move_to(padding + bar_width + bar_spacing + 5, height - 10);
            cr.show_text(@"Losses: $losses");
        });

        content.append(chart_area);

        double rate = total > 0 ? ((double)wins / total) * 100 : 0;
        var summary = new Gtk.Label(null);
        summary.set_markup(@"<span size='large'>Win Rate: <span color='#2ec27e'><b>%d%%</b></span></span>".printf((int)rate));
        content.append(summary);

        dialog.child = content;

        // Dialog anzeigen
        dialog.present(this);
    }
    // Hilfsfunktion für abgerundete Balken
    private void draw_rounded_rect(Cairo.Context cr, double x, double y, double w, double h, double r) {
        if (h < r) r = h / 2;
        cr.new_sub_path();
        cr.arc(x + w - r, y + r, r, -Math.PI / 2, 0);
        cr.arc(x + w - r, y + h - r, r, 0, Math.PI / 2);
        cr.arc(x + r, y + h - r, r, Math.PI / 2, Math.PI);
        cr.arc(x + r, y + r, r, Math.PI, 3 * Math.PI / 2);
        cr.close_path();
    }

    private void save_stats() {
        try {
            FileUtils.set_contents(save_path, @"$wins,$losses");
        } catch (Error e) { stderr.printf("Save error: %s\n", e.message); }
    }

    private void load_stats() {
        if (!FileUtils.test(save_path, FileTest.EXISTS)) return;
        try {
            string content;
            FileUtils.get_contents(save_path, out content);
            var parts = content.split(",");
            if (parts.length == 2) {
                wins = int.parse(parts[0]);
                losses = int.parse(parts[1]);
            }
        } catch (Error e) { stderr.printf("Load error: %s\n", e.message); }
    }
}
