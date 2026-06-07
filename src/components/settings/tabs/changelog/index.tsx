/*
 * Vencord, a Discord client mod
 * Copyright (c) 2025 Vendicated and contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import "./styles.css";

import { Button } from "@components/Button";
import { Card } from "@components/Card";
import { Divider } from "@components/Divider";
import { ErrorCard } from "@components/ErrorCard";
import { Heading } from "@components/Heading";
import { DeleteIcon } from "@components/Icons";
import { Link } from "@components/Link";
import { Paragraph } from "@components/Paragraph";
import { SettingsTab, wrapTab } from "@components/settings/tabs/BaseTab";
import { HashLink } from "@components/settings/tabs/updater/Components";
import { Margins } from "@utils/margins";
import { useAwaiter } from "@utils/react";
import { getRepo, UpdateLogger } from "@utils/updater";
import { Alerts, React, Toasts } from "@webpack/common";

import gitHash from "~git-hash";

import {
    ChangelogEntry,
    ChangelogHistory,
    clearChangelogHistory,
    clearIndividualLog,
    formatTimestamp,
    getChangelogHistory,
    getCommitsSinceLastSeen,
    getLastRepositoryCheckHash,
    getNewPlugins,
    getNewSettings,
    getNewSettingsEntries,
    getNewSettingsSize,
    getUpdatedPlugins,
    initializeChangelog,
    saveUpdateSession,
    UpdateSession,
} from "./changelogManager";

import {
    NewPluginsCompact,
    NewPluginsSection
} from "./NewPluginsSection";

function ChangelogCard({
    entry,
    repo,
    repoPending,
}: {
    entry: ChangelogEntry;
    repo: string;
    repoPending: boolean;
}) {

    return (
        <Card className="vc-changelog-entry">

            <div
                style={{
                    display: "flex",
                    flexDirection: "column",
                    gap: "0.25em",
                }}
            >

                <div className="vc-changelog-entry-header">

                    <code className="vc-changelog-entry-hash">

                        <HashLink
                            repo={repo || ""}
                            hash={entry.hash}
                            disabled={
                                repoPending || !repo
                            }
                        />

                    </code>

                    <span className="vc-changelog-entry-author">
                        by {entry.author}
                    </span>

                </div>

                <div className="vc-changelog-entry-message">
                    {entry.message}
                </div>

            </div>

        </Card>
    );
}

function UpdateLogCard({
    log,
    repo,
    repoPending,
    isExpanded,
    onToggleExpand,
    onClearLog,
}: {
    log: UpdateSession;
    repo: string;
    repoPending: boolean;
    isExpanded: boolean;
    onToggleExpand: () => void;
    onClearLog: (logId: string) => void;
}) {

    const isRepositoryFetch =
        log.type === "repository_fetch" ||
        (
            log.type === undefined &&
            log.fromHash === log.toHash &&
            log.commits.length === 0
        );

    const isUpToDate =
        log.fromHash === log.toHash;

    return (
        <Card className="vc-changelog-log">

            <div
                className="vc-changelog-log-header"
                onClick={onToggleExpand}
            >

                <div className="vc-changelog-log-info">

                    <div className="vc-changelog-log-title">

                        <span>

                            {isRepositoryFetch
                                ? isUpToDate
                                    ? `Repository check: ${log.fromHash.slice(0, 7)} (up to date)`
                                    : `Repository check: ${log.fromHash.slice(0, 7)} → ${log.toHash.slice(0, 7)}`
                                : `Update: ${log.fromHash.slice(0, 7)} → ${log.toHash.slice(0, 7)}`}

                        </span>

                        <Button
                            size="min"
                            variant="secondary"
                            className="vc-changelog-delete-button"
                            style={{
                                padding: "4px",
                                color: "var(--status-danger)",
                                opacity: 0.6,
                                cursor: "pointer",
                                display: "flex",
                                alignItems: "center",
                                justifyContent: "center",
                            }}
                            onClick={e => {
                                e.stopPropagation();
                                onClearLog(log.id);
                            }}
                        >

                            <DeleteIcon
                                width={16}
                                height={16}
                            />

                        </Button>

                    </div>

                    <div className="vc-changelog-log-meta">

                        {formatTimestamp(log.timestamp)}

                        {log.commits.length > 0 &&
                            ` • ${log.commits.length} commits available`}

                        {log.commits.length === 0 &&
                            " • No new commits"}

                        {log.newPlugins.length > 0 &&
                            ` • ${log.newPlugins.length} new plugins`}

                        {log.updatedPlugins.length > 0 &&
                            ` • ${log.updatedPlugins.length} updated plugins`}

                        {log.newSettings &&
                            getNewSettingsSize(log.newSettings) > 0 &&
                            ` • ${
                                getNewSettingsEntries(log.newSettings)
                                    .reduce(
                                        (sum, [, arr]) =>
                                            sum + arr.length,
                                        0
                                    )
                            } new settings`}

                    </div>

                </div>

                <div
                    className={
                        `vc-changelog-log-toggle ${
                            isExpanded
                                ? "expanded"
                                : ""
                        }`
                    }
                >
                    ▼
                </div>

            </div>

            {isExpanded && (

                <div className="vc-changelog-log-content">

                    {log.newPlugins.length > 0 && (
                        <div className="vc-changelog-log-plugins">

                            <NewPluginsCompact
                                newPlugins={log.newPlugins}
                                maxDisplay={50}
                            />

                        </div>
                    )}

                    {log.updatedPlugins.length > 0 && (
                        <div className="vc-changelog-log-plugins">

                            <Heading
                                className={Margins.bottom8}
                            >
                                Updated Plugins
                            </Heading>

                            <NewPluginsCompact
                                newPlugins={log.updatedPlugins}
                                maxDisplay={50}
                            />

                        </div>
                    )}

                    {log.newSettings &&
                        getNewSettingsSize(log.newSettings) > 0 && (

                        <div className="vc-changelog-log-plugins">

                            <Heading
                                className={Margins.bottom8}
                            >
                                New Settings
                            </Heading>

                            <div className="vc-changelog-new-plugins-list">

                                {getNewSettingsEntries(
                                    log.newSettings
                                ).map(
                                    ([pluginName, settings]) =>
                                        settings.map(setting => (

                                            <span
                                                key={`${pluginName}-${setting}`}
                                                className="vc-changelog-new-plugin-tag"
                                                title={`New setting in ${pluginName}`}
                                            >
                                                {pluginName}.{setting}
                                            </span>

                                        )),
                                )}

                            </div>

                        </div>
                    )}

                    {log.commits.length > 0 && (

                        <div className="vc-changelog-log-commits">

                            <div className="vc-changelog-log-commits-list">

                                {log.commits.map(entry => (

                                    <ChangelogCard
                                        key={entry.hash}
                                        entry={entry}
                                        repo={repo || ""}
                                        repoPending={repoPending}
                                    />

                                ))}

                            </div>

                        </div>
                    )}

                </div>
            )}

        </Card>
    );
}

function ChangelogContent() {

    const [
        repo,
        repoErr,
        repoPending
    ] = useAwaiter(getRepo, {
        fallbackValue: "",
    });

    const [
        changelog,
        setChangelog
    ] = React.useState<ChangelogEntry[]>([]);

    const [
        changelogHistory,
        setChangelogHistory
    ] = React.useState<ChangelogHistory>([]);

    const [
        newPlugins,
        setNewPlugins
    ] = React.useState<string[]>([]);

    const [
        updatedPlugins,
        setUpdatedPlugins
    ] = React.useState<string[]>([]);

    const [
        isLoading,
        setIsLoading
    ] = React.useState(true);

    const [
        error,
        setError
    ] = React.useState<string | null>(null);

    const [
        expandedLogs,
        setExpandedLogs
    ] = React.useState<Set<string>>(
        new Set()
    );

    const [
        showHistory,
        setShowHistory
    ] = React.useState(false);

    const [
        recentlyChecked,
        setRecentlyChecked
    ] = React.useState(false);

    const toggleLogExpanded = (
        logId: string
    ) => {

        setExpandedLogs(prev => {

            const next = new Set(prev);

            if (next.has(logId)) {
                next.delete(logId);
            } else {
                next.add(logId);
            }

            return next;
        });
    };

    return (
        <>
            <Heading className={Margins.top16}>
                Fetch Changes
            </Heading>

            <Paragraph className={Margins.bottom16}>
                Check the repository for updates.
            </Paragraph>

            <div className="vc-changelog-controls">

                <Button
                    size="small"
                    disabled={
                        isLoading ||
                        repoPending ||
                        !!repoErr
                    }
                    variant={
                        recentlyChecked
                            ? "positive"
                            : "primary"
                    }
                >

                    {isLoading
                        ? "Loading..."
                        : recentlyChecked
                            ? "Repository Up to Date"
                            : "Fetch from Repository"}

                </Button>

            </div>

            {error && (

                <ErrorCard
                    style={{
                        padding: "1em",
                        marginTop: "1em"
                    }}
                >

                    <Paragraph>
                        {error}
                    </Paragraph>

                </ErrorCard>
            )}

            <Divider className={Margins.top20} />

            <Heading className={Margins.top20}>
                Repository
            </Heading>

            <Paragraph className={Margins.bottom8}>
                MallCord update repository.
            </Paragraph>

            <Paragraph color="text-subtle">

                {repoPending
                    ? "Loading..."
                    : repoErr
                        ? "Failed to retrieve repository"
                        : repo
                            ? (
                                <Link href={repo}>
                                    {repo
                                        .split("/")
                                        .slice(-2)
                                        .join("/")}
                                </Link>
                            )
                            : "Unknown repository"}

                {" "}

                (
                    <HashLink
                        repo={repo || ""}
                        hash={gitHash}
                        disabled={
                            repoPending || !repo
                        }
                    />
                )

            </Paragraph>

        </>
    );
}

function ChangelogTab() {
    return (
        <SettingsTab>
            <ChangelogContent />
        </SettingsTab>
    );
}

export default wrapTab(
    ChangelogTab,
    "Changelog"
);
