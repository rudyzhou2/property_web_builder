# To reload from console:
# load "#{Pwb::Engine.root}/lib/pwb/content_translations_seeder.rb"
module Pwb
  class ContentTranslationsSeeder
    class << self
      # Called by this rake task:
      # rake app:pwb:db:seed_pages                                  1 ↵
      def seed_page_parts!
        page_part_yml_filenames = [
          "about-us__content_html.yml", "home__about_us_services.yml",
          "privacy__content_html.yml", "legal__content_html.yml"
        ]

        page_part_yml_filenames.each do |filename|
          seed_page_part filename
        end
      end


      def seed_page_content_translations!
        I18n.available_locales.each do |locale|
          seed_locale locale.to_s
        end
      end

      def seed_page_basics!
        page_yml_filenames = [
          "sell.yml", "about.yml", "buy.yml",
          "rent.yml", "home.yml", "legal_notice.yml",
          "contact.yml", "privacy_policy.yml"
        ]

        page_yml_filenames.each do |page_yml_filename|
          seed_page page_yml_filename
        end
      end

      protected


      def seed_page yml_file
        page_seed_file = Pwb::Engine.root.join('db', 'yml_seeds', 'pages', yml_file)
        page_yml = YAML.load_file(page_seed_file)
        unless Pwb::Page.where(slug: page_yml[0]['slug']).count > 0
          Pwb::Page.create!(page_yml)
        end
      end


      def seed_page_part yml_file
        lf_seed_file = Pwb::Engine.root.join('db', 'yml_seeds', 'page_parts', yml_file)
        lf_yml = YAML.load_file(lf_seed_file)
        unless Pwb::PagePart.where({fragment_key: lf_yml[0]['fragment_key'],page_slug: lf_yml[0]['page_slug']}).count > 0
          Pwb::PagePart.create!(lf_yml)
        end
      end

      def seed_locale locale
        locale_seed_file = Pwb::Engine.root.join('db', 'yml_seeds', 'content_translations', locale + '.yml')
        unless File.exist? locale_seed_file
          return
        end
        yml = YAML.load_file(locale_seed_file)

        Pwb::PageSetup.all.each do |page_setup|
          page_setup.pages.each do |page|
            page_setup.fragment_configs.each do |fragment_config|
              fragment_label = fragment_config["label"]
              # Items in each locale seed file are nested as
              # page_slug/fragment_label and then the block labels
              unless yml[locale] && yml[locale][page.slug] && yml[locale][page.slug][fragment_label]
                # skip if there is no content to populate
                next
              end
              if yml[locale][page.slug][fragment_label]
                set_page_block_content locale, page.slug, fragment_config, yml[locale][page.slug][fragment_label]
              end
            end
          end
        end
      end

      def set_page_block_content locale, page_slug, fragment_config, seed_content
        page = Pwb::Page.find_by_slug page_slug
        # fragment_label uniquely identifies a fragment
        # and is also the name of the corresponding partial
        fragment_label = fragment_config["label"]

        # ensure path exists in details col of page
        unless page.details["fragments"].present?
          page.details["fragments"] = {}
        end
        unless page.details["fragments"][fragment_label].present?
          page.details["fragments"][fragment_label] = {}
        end

        # container for json to be attached to page details
        content_for_pf_locale = {"blocks" => {}}
        # {"blocks"=>{"title_a"=>{"content"=>"about our agency"}, "content_a"=>{"content"=>""}}}
        fragment_config["editorBlocks"].each do |configColBlocks|
          configColBlocks.each do |configRowBlock|
            row_block_label = configRowBlock["label"]
            row_block_content = ""
            # find the content for current block from within the seed content
            if seed_content[row_block_label]
              if configRowBlock["isImage"]
                photo = page.seed_fragment_photo fragment_label, row_block_label, seed_content[row_block_label]
                row_block_content = photo.present? ? photo.optimized_image_url : ""
              else
                row_block_content = seed_content[row_block_label]
              end
            end
            content_for_pf_locale["blocks"][row_block_label] = {"content"=>row_block_content}
          end
        end


        fragment_html = page.parse_page_part fragment_label, content_for_pf_locale


        # # and save in content model associated with page
        content_for_page = page.set_fragment_html fragment_label, locale, fragment_html
        # page_content_join_model = content_for_page.page_contents.find_by_page_id page.id
        sort_order = fragment_config["default_sort_order"] || 1
        page.set_fragment_sort_order fragment_label, sort_order


        # content_for_page.sort_order = fragment_config["default_sort_order"] || 1
        visible_on_page = false
        if fragment_config["default_visible_on_page"]
          visible_on_page = true
        end

        page.set_fragment_visibility fragment_label, visible_on_page
        # page_content_join_model.visible_on_page = visible_on_page
        # content_for_page.visible_on_page = visible_on_page
        content_for_page.save!

        page.details["fragments"][fragment_label][locale] = content_for_pf_locale
        page.save!

        # p "#{page.slug} page content set."
      end


      # def create_fragment_photo photo_file
      #   if ENV["RAILS_ENV"] == "test"
      #     # don't create photos for tests
      #     return nil
      #   end
      #   begin
      #     photo = Pwb::ContentPhoto.create
      #     photo.image = Pwb::Engine.root.join(photo_file).open
      #     photo.save!
      #   rescue Exception => e
      #     # log exception to console
      #     p e
      #     if photo
      #       photo.destroy!
      #     end
      #   end
      #   return photo
      # end


    end
  end
end