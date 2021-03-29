//
//  ArchiveTableViewController.swift
//  FormFit
//
//  Created by Davis Haupt on 2/20/21.
//  Copyright © 2021 Apple. All rights reserved.
//

import UIKit

class ArchiveCell: UITableViewCell {
    var filename: String?
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var repCount: UILabel!
}

class ArchiveTableViewController: UITableViewController {
    var files: [URL]?
    var workouts: [ExerciseInformation]?
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == "ArchiveSummary" {
            if let vc = segue.destination as? SummaryViewController, let btn = sender as? ArchiveCell, let filename = btn.filename, let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                let url = dir.appendingPathComponent(filename)
                do {
                    let workoutJson = try String(contentsOf: url, encoding: .utf8)
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let workout = try decoder.decode(ExerciseInformation.self, from: workoutJson.data(using: .utf8)!)
                    vc.reps = workout.repInfo
                    vc.exerciseName = workout.exerciseName
                } catch {
                    print(error)
                }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            print(dir)
            self.files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil).filter(isDataFile(_:)).reversed()
        }
        
        if let files = files {
            var workoutList = [ExerciseInformation]()
            for i in 0...files.count - 1 {
                let name = files[i].lastPathComponent
                do {
                    let workoutJson = try String(contentsOf: files[i], encoding: .utf8)
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let workout = try decoder.decode(ExerciseInformation.self, from: workoutJson.data(using: .utf8)!)
                    workoutList.append(workout)
                } catch {
                    print("list decode error on \(name): \(error)")
                }
            }
            workouts = workoutList.sorted(by: {$0.timeStamp! > $1.timeStamp!})
        }
        

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    func isDataFile(_ str: URL) -> Bool {
        return !(str.lastPathComponent.hasPrefix("segment") || str.lastPathComponent.hasPrefix("analytics"))
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return workouts?.count ?? 0
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ArchiveCell", for: indexPath) as! ArchiveCell
        if let files = files {
            cell.filename = files[indexPath.row].lastPathComponent
        }
        if let workouts = workouts {
            let workout = workouts[indexPath.row]
            let dateformat = DateFormatter()
            dateformat.dateFormat = "MM/dd/yy h:mm a"
            let fullDateString = dateformat.string(from: workout.date!)
            let dateString = String(describing: fullDateString.dropLast(8))
            let timeString = String(describing: fullDateString.dropFirst(9))
            cell.title.text = "\(workout.exerciseName!)s on \(dateString) at \(timeString)"
            cell.repCount.text = "\(workout.repInfo.count) reps"
        }
        return cell
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
