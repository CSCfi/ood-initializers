function get_files_url() {
  const home_link = $("a.dropdown-item[title='Home Directory']");
  const files_dropdown = home_link.closest(".dropdown-menu");
  return home_link.attr("href").split("/fs")[0];
}

function sort_files_links() {
  const files_dropdown = $("a.dropdown-item[title='Home Directory']").closest(".dropdown-menu");

  const files_url = get_files_url();
  const local_url = `${files_url}/fs`;

  const links = $(`#navbar a.dropdown-item[href^='${files_url}']`)
    .toArray()
    .map(e => $(e))
    .filter(e => !(e.attr("href").startsWith(local_url)))
    .sort((a, b) => a.attr("title").localeCompare(b.attr("title")))
    .map(e => e.closest("li"));
  links.forEach(l => l.detach().appendTo(files_dropdown));
}

function add_remote_links(remotes) {
  const files_url = get_files_url();
  const files_dropdown = $("a.dropdown-item[title='Home Directory']").closest(".dropdown-menu");

  for (const remote of (typeof remotes === "string" ? [remotes] : remotes)) {
    const remote_url = `${files_url}/${remote}`;
    const existing = $(`#navbar a.dropdown-item[title='${remote}'][href='${remote_url}']`);
    if (existing.length > 0) {
      continue;
    }
    const link = $("<a></a>", { "class": "dropdown-item" }).attr("title", remote).attr("href", remote_url);
    const icon = $("<i></i>", { "class": "fas fa-folder fa-fw app-icon" });
    const html = `
    <li>
      <a title="${remote}" class="dropdown-item" href="${remote_url}">
        <i id="" class="fas fa-folder fa-fw app-icon" title="FontAwesome icon specified: folder" aria-hidden="true"></i>
        ${remote}
      </a>
    </li>`;
    files_dropdown.append(html);
  }
  sort_files_links();
}

function remove_remote_links(remotes) {
  const files_url = get_files_url();
  for (const remote of (typeof remotes === "string" ? [remotes] : remotes)) {
    const remote_url = `${files_url}/${remote}`;
    $(`#navbar a.dropdown-item[title='${remote}'][href='${remote_url}']`).closest("li").remove();
  }
  sort_files_links();
}

