//
//  SavedPetTableViewCell.swift
//  PetRescuePlanner
//
//  Created by Daniel Rodosky on 11/10/17.
//  Copyright © 2017 Daniel Rodosky. All rights reserved.
//

import UIKit

class SavedPetTableViewCell: UITableViewCell {
    
    // MARK: - Outlets
    
    @IBOutlet weak var petImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    var pet: Pet? {
        didSet{
            self.updateViews()
        }
    }
    
    var petImage: UIImage? = nil
    
    // MARK: - Private Funcs
    
    func updateViews() {
        let redColor = UIColor(red: 222.0/255.0, green: 21.0/255.0, blue: 93.0/255.0, alpha: 1)
        let redForegroundAttribute = [NSAttributedStringKey.foregroundColor: redColor]
        
        guard let pet = pet, let petName = pet.name else { return }
        guard let petImage = petImage else {
            
            PetController.shared.fetchImageFor(pet: pet, number: 2, completion: { (success, image) in
                if !success {
                    NSLog("error fetchingpet in pet controller")
                    self.petImageView.image = #imageLiteral(resourceName: "DefaultCardIMGNoBorder")
                    let petNameString: NSMutableAttributedString = NSMutableAttributedString(string: "\(petName)", attributes: redForegroundAttribute)
                    self.nameLabel.attributedText = petNameString
                    self.descriptionLabel.text = pet.petDescription
                    self.setupConstraints()
                    return 
                }
                guard let image = image else { return }
                DispatchQueue.main.async {
                    self.petImageView.image = image
                    let petNameString: NSMutableAttributedString = NSMutableAttributedString(string: "\(petName)", attributes: redForegroundAttribute)
                    self.nameLabel.attributedText = petNameString
                    self.descriptionLabel.text = pet.petDescription
                    self.setupConstraints()
                }
            })
            return
        }
        
        petImageView.image = petImage
        let petNameString: NSMutableAttributedString = NSMutableAttributedString(string: "\(petName)", attributes: redForegroundAttribute)
        nameLabel.attributedText = petNameString
        descriptionLabel.text = pet.petDescription
        setupConstraints()
    }
    
    func setupConstraints() {
        
        petImageView.trailingAnchor.constraint(equalTo: nameLabel.leadingAnchor, constant: (0 - 8)).isActive = true
        petImageView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 8).isActive = true
        
        descriptionLabel.leadingAnchor.constraint(equalTo: petImageView.trailingAnchor, constant: 8).isActive = true
        descriptionLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 0).isActive = true
        
        petImageView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0).isActive = true
    }
}
















